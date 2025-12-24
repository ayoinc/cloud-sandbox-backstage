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

```d2
direction: down

app: Spark Application {
  style.fill: "#E3F2FD"
}

driver: Driver Program {
  style.fill: "#BBDEFB"
  
  context: SparkContext/SparkSession
  
  schedulers: Schedulers {
    direction: right
    dag: DAG Scheduler
    task: Task Scheduler
    dag -> task
  }
}

workers: Workers {
  direction: right
  
  executor1: Executor 1 (Worker 1) {
    style.fill: "#C8E6C9"
    tasks1: Tasks {
      t1: Task
      t2: Task
      t3: Task
      t4: Task
    }
    cache1: Cache (In-Memory) {
      style.fill: "#A5D6A7"
    }
  }
  
  executor2: Executor 2 (Worker 2) {
    style.fill: "#C8E6C9"
    tasks2: Tasks {
      t1: Task
      t2: Task
      t3: Task
      t4: Task
    }
    cache2: Cache (In-Memory) {
      style.fill: "#A5D6A7"
    }
  }
  
  executor3: Executor 3 (Worker 3) {
    style.fill: "#C8E6C9"
    tasks3: Tasks {
      t1: Task
      t2: Task
      t3: Task
      t4: Task
    }
    cache3: Cache (In-Memory) {
      style.fill: "#A5D6A7"
    }
  }
}

cluster_manager: Cluster Manager (Standalone/YARN/K8s/Mesos) {
  style.fill: "#FFE0B2"
}

app -> driver
driver -> workers: distribute tasks
cluster_manager -> workers: manage resources
cluster_manager -> driver: allocate resources
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
