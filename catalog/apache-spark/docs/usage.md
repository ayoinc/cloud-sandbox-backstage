# Apache Spark Usage Guide

## Data Processing Pipeline

```d2
direction: right

sources: Data Sources {
  style.fill: "#E3F2FD"
  
  s3: S3/HDFS {
    style.fill: "#BBDEFB"
  }
  kafka: Kafka {
    style.fill: "#BBDEFB"
  }
  jdbc: JDBC/Databases {
    style.fill: "#BBDEFB"
  }
}

spark: Spark Processing {
  style.fill: "#E8F5E9"
  
  extract: Extract {
    style.fill: "#C8E6C9"
    read: "spark.read.*"
  }
  
  transform: Transform {
    style.fill: "#A5D6A7"
    ops: |md
      - filter()
      - select()
      - groupBy()
      - join()
      - agg()
    |
  }
  
  load: Load {
    style.fill: "#81C784"
    write: "df.write.*"
  }
  
  extract -> transform -> load
}

sinks: Data Sinks {
  style.fill: "#FFF3E0"
  
  delta: Delta Lake {
    style.fill: "#FFE0B2"
  }
  warehouse: Data Warehouse {
    style.fill: "#FFE0B2"
  }
  streaming: Streaming Output {
    style.fill: "#FFE0B2"
  }
}

sources.s3 -> spark.extract
sources.kafka -> spark.extract
sources.jdbc -> spark.extract

spark.load -> sinks.delta
spark.load -> sinks.warehouse
spark.load -> sinks.streaming
```

## Prerequisites

- Java 8, 11, or 17
- Python 3.8+ (for PySpark)
- Docker (for containerized deployment)
- Sufficient memory (8GB+ per worker recommended)

## Deployment with Docker Compose

### Standalone Cluster

```yaml
# docker-compose.yml
version: '3.8'

services:
  spark-master:
    image: bitnami/spark:3.5
    container_name: spark-master
    environment:
      - SPARK_MODE=master
      - SPARK_MASTER_HOST=spark-master
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
    ports:
      - "8080:8080"   # Spark UI
      - "7077:7077"   # Spark master port
      - "4040:4040"   # Application UI
    volumes:
      - ./data:/data
      - ./jobs:/jobs
    networks:
      - spark-network

  spark-worker-1:
    image: bitnami/spark:3.5
    container_name: spark-worker-1
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_MEMORY=4G
      - SPARK_WORKER_CORES=2
    depends_on:
      - spark-master
    volumes:
      - ./data:/data
    networks:
      - spark-network

  spark-worker-2:
    image: bitnami/spark:3.5
    container_name: spark-worker-2
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_MEMORY=4G
      - SPARK_WORKER_CORES=2
    depends_on:
      - spark-master
    volumes:
      - ./data:/data
    networks:
      - spark-network

  spark-history:
    image: bitnami/spark:3.5
    container_name: spark-history
    environment:
      - SPARK_MODE=master
    command: /opt/bitnami/spark/sbin/start-history-server.sh
    ports:
      - "18080:18080"
    volumes:
      - spark-logs:/tmp/spark-events
    networks:
      - spark-network

  jupyter:
    image: jupyter/pyspark-notebook:latest
    container_name: jupyter
    ports:
      - "8888:8888"
    environment:
      - SPARK_MASTER=spark://spark-master:7077
    volumes:
      - ./notebooks:/home/jovyan/work
      - ./data:/data
    networks:
      - spark-network

volumes:
  spark-logs:

networks:
  spark-network:
    driver: bridge
```

## Code Examples

### ETL Pipeline

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp, md5, concat_ws
from pyspark.sql.types import *
from delta import DeltaTable

# Initialize Spark with Delta Lake
spark = SparkSession.builder \
    .appName("ETL Pipeline") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

def extract_data():
    """Extract data from multiple sources"""
    # Read from S3/Parquet
    orders_df = spark.read.parquet("s3a://bucket/raw/orders/")
    
    # Read from PostgreSQL
    customers_df = spark.read \
        .format("jdbc") \
        .option("url", "jdbc:postgresql://postgres:5432/ecommerce") \
        .option("dbtable", "customers") \
        .option("user", "user") \
        .option("password", "password") \
        .option("numPartitions", 8) \
        .load()
    
    return orders_df, customers_df

def transform_data(orders_df, customers_df):
    """Apply transformations"""
    # Join and enrich
    enriched_df = orders_df.join(
        customers_df,
        orders_df.customer_id == customers_df.id,
        "left"
    )
    
    # Add derived columns
    result_df = enriched_df \
        .withColumn("order_year", year(col("order_date"))) \
        .withColumn("order_month", month(col("order_date"))) \
        .withColumn("total_with_tax", col("total") * 1.08) \
        .withColumn("customer_segment", 
            when(col("total") > 1000, "premium")
            .when(col("total") > 100, "regular")
            .otherwise("basic")
        ) \
        .withColumn("processed_at", current_timestamp()) \
        .withColumn("row_hash", md5(concat_ws("||", 
            col("order_id"), col("customer_id"), col("total")
        )))
    
    return result_df

def load_data_delta(df, table_path):
    """Upsert to Delta Lake"""
    if DeltaTable.isDeltaTable(spark, table_path):
        delta_table = DeltaTable.forPath(spark, table_path)
        
        delta_table.alias("target").merge(
            df.alias("source"),
            "target.order_id = source.order_id"
        ).whenMatchedUpdate(
            condition="source.row_hash != target.row_hash",
            set={
                "total": "source.total",
                "status": "source.status",
                "processed_at": "source.processed_at",
                "row_hash": "source.row_hash"
            }
        ).whenNotMatchedInsertAll() \
        .execute()
    else:
        df.write \
            .format("delta") \
            .mode("overwrite") \
            .partitionBy("order_year", "order_month") \
            .save(table_path)

def main():
    orders_df, customers_df = extract_data()
    transformed_df = transform_data(orders_df, customers_df)
    load_data_delta(transformed_df, "s3a://bucket/delta/enriched_orders")
    
    # Optimize Delta table
    spark.sql(f"OPTIMIZE delta.`s3a://bucket/delta/enriched_orders` ZORDER BY (customer_id)")
    
    # Vacuum old files
    spark.sql(f"VACUUM delta.`s3a://bucket/delta/enriched_orders` RETAIN 168 HOURS")

if __name__ == "__main__":
    main()
```

### Real-Time Streaming Analytics

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Streaming Analytics") \
    .config("spark.sql.shuffle.partitions", 20) \
    .getOrCreate()

# Define event schema
event_schema = StructType([
    StructField("event_id", StringType()),
    StructField("user_id", StringType()),
    StructField("event_type", StringType()),
    StructField("page", StringType()),
    StructField("timestamp", TimestampType()),
    StructField("properties", MapType(StringType(), StringType()))
])

# Read from Kafka
events_df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("subscribe", "user-events") \
    .option("startingOffsets", "latest") \
    .option("maxOffsetsPerTrigger", 10000) \
    .load() \
    .select(from_json(col("value").cast("string"), event_schema).alias("event")) \
    .select("event.*")

# Session window analysis
sessions_df = events_df \
    .withWatermark("timestamp", "30 minutes") \
    .groupBy(
        session_window("timestamp", "30 minutes").alias("session"),
        "user_id"
    ) \
    .agg(
        count("*").alias("event_count"),
        collect_list("event_type").alias("event_sequence"),
        first("timestamp").alias("session_start"),
        last("timestamp").alias("session_end"),
        countDistinct("page").alias("pages_visited")
    )

# Real-time metrics
metrics_df = events_df \
    .withWatermark("timestamp", "1 minute") \
    .groupBy(
        window("timestamp", "1 minute"),
        "event_type"
    ) \
    .agg(
        count("*").alias("count"),
        approx_count_distinct("user_id").alias("unique_users")
    )

# Write sessions to Delta Lake
sessions_query = sessions_df \
    .writeStream \
    .outputMode("append") \
    .format("delta") \
    .option("checkpointLocation", "/checkpoints/sessions") \
    .option("path", "s3a://bucket/delta/sessions") \
    .trigger(processingTime="1 minute") \
    .start()

# Write metrics to Prometheus Pushgateway (via foreachBatch)
def write_to_pushgateway(batch_df, batch_id):
    metrics = batch_df.collect()
    for row in metrics:
        # Push to Prometheus Pushgateway
        pass

metrics_query = metrics_df \
    .writeStream \
    .outputMode("update") \
    .foreachBatch(write_to_pushgateway) \
    .trigger(processingTime="30 seconds") \
    .start()

spark.streams.awaitAnyTermination()
```

### Machine Learning Pipeline

```python
from pyspark.sql import SparkSession
from pyspark.ml import Pipeline, PipelineModel
from pyspark.ml.feature import *
from pyspark.ml.classification import GBTClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder

spark = SparkSession.builder \
    .appName("ML Pipeline") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

# Load training data
df = spark.read.parquet("s3a://bucket/data/training/")

# Feature engineering pipeline
categorical_cols = ["category", "region", "channel"]
numeric_cols = ["amount", "frequency", "recency"]

# String indexers for categorical variables
indexers = [
    StringIndexer(inputCol=c, outputCol=f"{c}_idx", handleInvalid="keep")
    for c in categorical_cols
]

# One-hot encoders
encoders = [
    OneHotEncoder(inputCol=f"{c}_idx", outputCol=f"{c}_vec")
    for c in categorical_cols
]

# Assemble all features
assembler = VectorAssembler(
    inputCols=[f"{c}_vec" for c in categorical_cols] + numeric_cols,
    outputCol="raw_features"
)

# Scale features
scaler = StandardScaler(
    inputCol="raw_features",
    outputCol="features",
    withStd=True,
    withMean=False
)

# Classifier
gbt = GBTClassifier(
    featuresCol="features",
    labelCol="label",
    maxIter=100,
    maxDepth=5
)

# Build pipeline
pipeline = Pipeline(stages=indexers + encoders + [assembler, scaler, gbt])

# Cross-validation
paramGrid = ParamGridBuilder() \
    .addGrid(gbt.maxDepth, [3, 5, 7]) \
    .addGrid(gbt.maxIter, [50, 100]) \
    .addGrid(gbt.stepSize, [0.1, 0.01]) \
    .build()

evaluator = BinaryClassificationEvaluator(
    labelCol="label",
    rawPredictionCol="rawPrediction",
    metricName="areaUnderROC"
)

cv = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=paramGrid,
    evaluator=evaluator,
    numFolds=5,
    parallelism=4
)

# Split data
train_df, test_df = df.randomSplit([0.8, 0.2], seed=42)

# Train model
cv_model = cv.fit(train_df)
best_model = cv_model.bestModel

# Evaluate
predictions = best_model.transform(test_df)
auc = evaluator.evaluate(predictions)
print(f"Test AUC: {auc}")

# Feature importance (for tree-based models)
gbt_model = best_model.stages[-1]
feature_importance = gbt_model.featureImportances.toArray()

# Save model
best_model.write().overwrite().save("s3a://bucket/models/churn-model")

# Load and use model
loaded_model = PipelineModel.load("s3a://bucket/models/churn-model")
new_predictions = loaded_model.transform(new_data)
```

## Performance Optimization

### Partition Strategies

```python
# Repartition for even distribution
df = df.repartition(200)

# Repartition by key for joins
df = df.repartition("customer_id")

# Coalesce to reduce partitions (no shuffle)
df = df.coalesce(10)

# Partition output by date
df.write \
    .partitionBy("year", "month", "day") \
    .parquet("s3a://bucket/output/")

# Bucketing for repeated joins
df.write \
    .bucketBy(100, "user_id") \
    .sortBy("user_id") \
    .saveAsTable("bucketed_users")
```

### Join Optimization

```python
# Broadcast small tables
from pyspark.sql.functions import broadcast

result = large_df.join(broadcast(small_df), "key")

# Hint for specific join type
result = df1.hint("SHUFFLE_MERGE").join(df2, "key")
result = df1.hint("SHUFFLE_HASH").join(df2, "key")

# Avoid Cartesian products
spark.conf.set("spark.sql.crossJoin.enabled", "false")
```

### Caching Strategies

```python
# Cache in memory
df.cache()
df.count()  # Materialize cache

# Persist with storage level
from pyspark import StorageLevel

df.persist(StorageLevel.MEMORY_AND_DISK_SER)

# Unpersist when done
df.unpersist()

# Check cached DataFrames
spark.catalog.listTables()
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| OutOfMemoryError (driver) | Large collect() or broadcast | Increase driver memory, avoid collect() |
| OutOfMemoryError (executor) | Data skew, large partitions | Repartition, increase executor memory |
| Shuffle spill to disk | Insufficient memory for shuffle | Increase `spark.memory.fraction`, add executors |
| Data skew | Uneven key distribution | Salting, repartition, AQE skew join handling |
| Slow jobs | Too many/few partitions | Tune `spark.sql.shuffle.partitions` |
| Stage failures | Task timeouts, resource limits | Increase timeouts, check data source |
| Job stuck | Deadlock, resource starvation | Check executor logs, increase resources |

### Debug Commands

```python
# View execution plan
df.explain(mode="extended")
df.explain(mode="cost")

# Check partitions
print(f"Partitions: {df.rdd.getNumPartitions()}")

# View cached data
spark.catalog.listTables()

# Check active jobs
spark.sparkContext.statusTracker().getActiveJobIds()

# Configure logging
spark.sparkContext.setLogLevel("WARN")
```

## Best Practices

### Code Quality

1. **Use DataFrames over RDDs** - Better optimization
2. **Avoid UDFs when possible** - Use built-in functions
3. **Minimize shuffles** - Use broadcast joins, proper partitioning
4. **Filter early** - Push filters as close to source as possible
5. **Cache strategically** - Only cache reused DataFrames

### Resource Management

1. **Right-size executors** - 4-8 cores, 16-32GB memory typical
2. **Enable dynamic allocation** - Scale based on workload
3. **Use spot/preemptible instances** - Cost savings for batch jobs
4. **Monitor memory usage** - Watch for spill and GC time

### Production Checklist

- [ ] Set appropriate shuffle partitions (2-3x cores)
- [ ] Enable Adaptive Query Execution
- [ ] Configure proper logging and event history
- [ ] Set up monitoring and alerting
- [ ] Use checkpointing for streaming
- [ ] Test failure recovery
- [ ] Version control Spark configs
- [ ] Document data lineage
