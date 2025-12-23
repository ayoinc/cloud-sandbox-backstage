# Apache Spark

Unified analytics engine for large-scale data processing, machine learning, and real-time streaming with in-memory computing.

## Quick Start

### Start Spark with Docker

```bash
# Start Spark standalone cluster
docker run -d --name spark-master \
  -p 8080:8080 -p 7077:7077 \
  -e SPARK_MODE=master \
  bitnami/spark:3.5

# Start worker nodes
docker run -d --name spark-worker-1 \
  -e SPARK_MODE=worker \
  -e SPARK_MASTER_URL=spark://spark-master:7077 \
  --link spark-master:spark-master \
  bitnami/spark:3.5

# Access Spark shell
docker exec -it spark-master spark-shell --master spark://spark-master:7077

# Or PySpark
docker exec -it spark-master pyspark --master spark://spark-master:7077
```

### Submit a Spark Job

```bash
# Submit application
spark-submit \
  --master spark://spark-master:7077 \
  --deploy-mode client \
  --driver-memory 4g \
  --executor-memory 8g \
  --executor-cores 4 \
  --num-executors 3 \
  /path/to/my-app.py

# Submit with dependencies
spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0 \
  --py-files utils.zip \
  my-streaming-app.py
```

## Features

| Feature | Description |
|---------|-------------|
| **Spark SQL** | SQL queries on structured data with DataFrames API |
| **Spark Streaming** | Micro-batch and continuous stream processing |
| **MLlib** | Scalable machine learning library |
| **GraphX** | Graph processing and analytics |
| **Structured Streaming** | Stream processing with DataFrame semantics |
| **Delta Lake** | ACID transactions on data lakes |
| **Adaptive Query Execution** | Runtime query optimization |
| **Dynamic Resource Allocation** | Auto-scaling executors based on workload |

## Architecture

```
                                    ┌──────────────────────────────────────────────┐
                                    │              Spark Application               │
                                    └──────────────────────────────────────────────┘
                                                         │
                                    ┌────────────────────▼────────────────────┐
                                    │              Driver Program              │
                                    │         (SparkContext/SparkSession)      │
                                    │                                          │
                                    │  ┌────────────┐    ┌─────────────────┐  │
                                    │  │    DAG     │    │ Task Scheduler  │  │
                                    │  │ Scheduler  │───▶│                 │  │
                                    │  └────────────┘    └─────────────────┘  │
                                    └────────────────────┬────────────────────┘
                                                         │
                              ┌──────────────────────────┼──────────────────────────┐
                              │                          │                          │
                      ┌───────▼───────┐          ┌───────▼───────┐          ┌───────▼───────┐
                      │   Executor 1  │          │   Executor 2  │          │   Executor 3  │
                      │   (Worker 1)  │          │   (Worker 2)  │          │   (Worker 3)  │
                      ├───────────────┤          ├───────────────┤          ├───────────────┤
                      │ Task │ Task   │          │ Task │ Task   │          │ Task │ Task   │
                      │ Task │ Task   │          │ Task │ Task   │          │ Task │ Task   │
                      ├───────────────┤          ├───────────────┤          ├───────────────┤
                      │    Cache      │          │    Cache      │          │    Cache      │
                      │  (In-Memory)  │          │  (In-Memory)  │          │  (In-Memory)  │
                      └───────────────┘          └───────────────┘          └───────────────┘

                                    ┌──────────────────────────────────────────────┐
                                    │            Cluster Manager                    │
                                    │   (Standalone / YARN / Kubernetes / Mesos)   │
                                    └──────────────────────────────────────────────┘
```

## Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Local** | Single JVM with multiple threads | Development, testing |
| **Standalone** | Spark's built-in cluster manager | Simple deployments |
| **YARN** | Hadoop resource manager | Hadoop ecosystem integration |
| **Kubernetes** | Container orchestration | Cloud-native deployments |
| **Mesos** | General cluster manager | Mixed workloads |

## Data Sources

| Source | Format | Example |
|--------|--------|---------|
| Files | Parquet, ORC, JSON, CSV, Avro | `spark.read.parquet("s3://bucket/data")` |
| Databases | JDBC, Hive, Delta Lake | `spark.read.jdbc(url, table, props)` |
| Streaming | Kafka, Kinesis, Files | `spark.readStream.format("kafka")` |
| Cloud | S3, GCS, ADLS, HDFS | Native cloud connectors |

## Version Information

- **Apache Spark**: 3.5.x (current stable)
- **Scala**: 2.12.x / 2.13.x
- **Python**: 3.8+ (PySpark)
- **Java**: 8, 11, 17

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and components
- [Usage](usage.md) - Code examples, optimization, and best practices
