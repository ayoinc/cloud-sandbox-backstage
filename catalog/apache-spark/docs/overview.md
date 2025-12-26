# Apache Spark Overview

## Architecture Deep Dive

### Job Execution Flow

```d2
direction: down

user_code: User Code {
  style.fill: "#E8F5E9"
  code: "df.filter().groupBy().agg().show()"
}

logical_plan: Logical Plan {
  style.fill: "#FFF3E0"
  desc: Unoptimized query representation
}

catalyst: Catalyst Optimizer {
  style.fill: "#E3F2FD"
  desc: Predicate pushdown, column pruning, etc.
}

physical_plan: Physical Plan {
  style.fill: "#F3E5F5"
  desc: Optimized execution strategy
}

dag_scheduler: DAG Scheduler {
  style.fill: "#FFEBEE"

  stages: Stages (based on shuffles) {
    direction: right

    stage1: Stage 1 {
      style.fill: "#FFCDD2"
      t1: Task 1
      t2: Task 2
      t3: Task 3
    }

    stage2: Stage 2 {
      style.fill: "#FFCDD2"
      t1: Task 1
      t2: Task 2
      t3: Task 3
    }

    stage3: Stage 3 {
      style.fill: "#FFCDD2"
      t1: Task 1
      t2: Task 2
    }

    stage1 -> stage2: Shuffle
    stage2 -> stage3: Shuffle
  }
}

user_code -> logical_plan: parse
logical_plan -> catalyst: optimize
catalyst -> physical_plan: generate
physical_plan -> dag_scheduler: schedule
```

### RDD vs DataFrame vs Dataset

| Feature          | RDD          | DataFrame | Dataset          |
| ---------------- | ------------ | --------- | ---------------- |
| **Type Safety**  | Compile-time | Runtime   | Compile-time     |
| **Optimization** | Manual       | Catalyst  | Catalyst         |
| **API**          | Functional   | SQL-like  | Functional + SQL |
| **Schema**       | No           | Yes       | Yes              |
| **Language**     | All          | All       | Scala/Java       |
| **Performance**  | Lower        | Higher    | Higher           |

### Memory Management

```d2
direction: down

executor: Executor Memory (spark.executor.memory) {
  unified: Unified Memory (60% default) {
    storage: Storage Memory (Cached RDDs) {
      shape: rectangle
    }
    execution: Execution Memory (Shuffles, Joins) {
      shape: rectangle
    }
    storage <-> execution: Can borrow from each other dynamically
  }

  reserved: Reserved Memory (300MB)

  user: User Memory (40% - reserved) - User data structures, UDFs
}
```

## Configuration

### spark-defaults.conf

```properties
# Application settings
spark.app.name                         MySparkApp
spark.master                           spark://master:7077

# Memory configuration
spark.driver.memory                    4g
spark.executor.memory                  8g
spark.executor.memoryOverhead          1g
spark.memory.fraction                  0.6
spark.memory.storageFraction           0.5

# Executor settings
spark.executor.cores                   4
spark.executor.instances               10
spark.dynamicAllocation.enabled        true
spark.dynamicAllocation.minExecutors   2
spark.dynamicAllocation.maxExecutors   20

# Shuffle settings
spark.sql.shuffle.partitions           200
spark.shuffle.compress                 true
spark.shuffle.spill.compress           true

# Serialization
spark.serializer                       org.apache.spark.serializer.KryoSerializer
spark.kryoserializer.buffer.max        1024m

# SQL optimization
spark.sql.adaptive.enabled             true
spark.sql.adaptive.coalescePartitions.enabled  true
spark.sql.adaptive.skewJoin.enabled    true

# Speculation
spark.speculation                      true
spark.speculation.multiplier           1.5
spark.speculation.quantile             0.75

# Event logging
spark.eventLog.enabled                 true
spark.eventLog.dir                     hdfs:///spark-logs
spark.history.fs.logDirectory          hdfs:///spark-logs
```

### Kubernetes Configuration

```yaml
# spark-application.yaml (Spark Operator)
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: spark-etl-job
  namespace: spark
spec:
  type: Python
  mode: cluster
  image: spark:3.5.0-python
  imagePullPolicy: IfNotPresent
  mainApplicationFile: s3a://bucket/jobs/etl.py
  sparkVersion: '3.5.0'

  sparkConf:
    spark.sql.adaptive.enabled: 'true'
    spark.sql.shuffle.partitions: '200'
    spark.hadoop.fs.s3a.impl: org.apache.hadoop.fs.s3a.S3AFileSystem
    spark.hadoop.fs.s3a.aws.credentials.provider: com.amazonaws.auth.WebIdentityTokenCredentialsProvider

  driver:
    cores: 2
    memory: '4g'
    serviceAccount: spark-sa
    labels:
      app: spark-driver

  executor:
    cores: 4
    instances: 5
    memory: '8g'
    labels:
      app: spark-executor

  dynamicAllocation:
    enabled: true
    initialExecutors: 2
    minExecutors: 2
    maxExecutors: 20

  restartPolicy:
    type: OnFailure
    onFailureRetries: 3
    onFailureRetryInterval: 10
    onSubmissionFailureRetries: 5
    onSubmissionFailureRetryInterval: 20
```

## Spark SQL and DataFrames

### Creating DataFrames

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, avg, count, when
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType

spark = SparkSession.builder \
    .appName("MyApp") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

# From files
df = spark.read.parquet("s3://bucket/data/")
df = spark.read.format("delta").load("s3://bucket/delta-table")
df = spark.read.json("hdfs:///data/events.json")

# From JDBC
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://host:5432/db") \
    .option("dbtable", "users") \
    .option("user", "user") \
    .option("password", "password") \
    .option("numPartitions", 10) \
    .option("partitionColumn", "id") \
    .option("lowerBound", 1) \
    .option("upperBound", 1000000) \
    .load()

# With explicit schema
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("value", DoubleType(), True)
])
df = spark.read.schema(schema).csv("s3://bucket/data.csv", header=True)
```

### DataFrame Operations

```python
# Transformations
result = df \
    .filter(col("status") == "active") \
    .select("user_id", "amount", "category") \
    .withColumn("amount_usd", col("amount") * 1.1) \
    .withColumn("size", when(col("amount") > 1000, "large").otherwise("small")) \
    .groupBy("category") \
    .agg(
        sum("amount").alias("total_amount"),
        avg("amount").alias("avg_amount"),
        count("*").alias("count")
    ) \
    .orderBy(col("total_amount").desc()) \
    .limit(100)

# Window functions
from pyspark.sql.window import Window

window_spec = Window.partitionBy("category").orderBy(col("amount").desc())
df_ranked = df.withColumn("rank", row_number().over(window_spec))

# SQL queries
df.createOrReplaceTempView("transactions")
result = spark.sql("""
    SELECT
        category,
        SUM(amount) as total,
        AVG(amount) as average
    FROM transactions
    WHERE date >= '2024-01-01'
    GROUP BY category
    HAVING SUM(amount) > 10000
    ORDER BY total DESC
""")
```

## Structured Streaming

```python
# Read from Kafka
stream_df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("subscribe", "events") \
    .option("startingOffsets", "latest") \
    .load()

# Process stream
from pyspark.sql.functions import from_json, window

schema = StructType([
    StructField("user_id", StringType()),
    StructField("event_type", StringType()),
    StructField("timestamp", TimestampType()),
    StructField("value", DoubleType())
])

parsed_df = stream_df \
    .select(from_json(col("value").cast("string"), schema).alias("data")) \
    .select("data.*")

# Windowed aggregation
windowed_counts = parsed_df \
    .withWatermark("timestamp", "10 minutes") \
    .groupBy(
        window("timestamp", "5 minutes", "1 minute"),
        "event_type"
    ) \
    .count()

# Write to sink
query = windowed_counts \
    .writeStream \
    .outputMode("update") \
    .format("console") \
    .option("checkpointLocation", "/checkpoints/events") \
    .trigger(processingTime="30 seconds") \
    .start()

# Write to Kafka
query = parsed_df \
    .selectExpr("CAST(user_id AS STRING) AS key", "to_json(struct(*)) AS value") \
    .writeStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("topic", "processed-events") \
    .option("checkpointLocation", "/checkpoints/kafka-sink") \
    .start()
```

## MLlib Machine Learning

```python
from pyspark.ml import Pipeline
from pyspark.ml.feature import VectorAssembler, StandardScaler, StringIndexer
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder

# Prepare features
indexer = StringIndexer(inputCol="category", outputCol="categoryIndex")
assembler = VectorAssembler(
    inputCols=["feature1", "feature2", "feature3", "categoryIndex"],
    outputCol="features"
)
scaler = StandardScaler(inputCol="features", outputCol="scaledFeatures")
rf = RandomForestClassifier(
    featuresCol="scaledFeatures",
    labelCol="label",
    numTrees=100
)

# Build pipeline
pipeline = Pipeline(stages=[indexer, assembler, scaler, rf])

# Hyperparameter tuning
paramGrid = ParamGridBuilder() \
    .addGrid(rf.numTrees, [50, 100, 200]) \
    .addGrid(rf.maxDepth, [5, 10, 15]) \
    .build()

evaluator = MulticlassClassificationEvaluator(
    labelCol="label",
    predictionCol="prediction",
    metricName="accuracy"
)

crossval = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=paramGrid,
    evaluator=evaluator,
    numFolds=3
)

# Train and evaluate
train_df, test_df = df.randomSplit([0.8, 0.2], seed=42)
model = crossval.fit(train_df)
predictions = model.transform(test_df)

accuracy = evaluator.evaluate(predictions)
print(f"Accuracy: {accuracy}")

# Save model
model.bestModel.write().overwrite().save("s3://bucket/models/rf-model")
```

## Monitoring and Metrics

### Spark UI

| Tab             | Information                          |
| --------------- | ------------------------------------ |
| **Jobs**        | Active/completed jobs, stages, tasks |
| **Stages**      | DAG visualization, task metrics      |
| **Storage**     | Cached RDDs/DataFrames               |
| **Environment** | Spark properties, classpath          |
| **Executors**   | Memory/disk usage, task statistics   |
| **SQL**         | Query plans, execution details       |

### Prometheus Metrics

```properties
# spark-defaults.conf
spark.ui.prometheus.enabled          true
spark.metrics.conf.*.sink.prometheusServlet.class  org.apache.spark.metrics.sink.PrometheusServlet
spark.metrics.conf.*.sink.prometheusServlet.path   /metrics/prometheus
```

### Key Metrics to Monitor

| Metric               | Description                      | Alert Threshold    |
| -------------------- | -------------------------------- | ------------------ |
| Executor memory used | Heap usage per executor          | > 85%              |
| GC time              | Time spent in garbage collection | > 10% of task time |
| Shuffle read/write   | Data shuffled between stages     | Sudden spikes      |
| Task failures        | Failed task count                | > 5% failure rate  |
| Stage duration       | Time per stage                   | 10x increase       |
| Spill to disk        | Memory spilling                  | Any spill events   |
