"""Processed zone to curated zone.

Every top-level prefix of the source location is one dataset of Parquet files.
Records without any value are dropped and the result replaces the dataset of
the same name in the target location, where the crawler of the curated zone
turns it into a table for Athena, Redshift and the BI tools.

This is the place for the business rules of each dataset: joins, aggregations
and the selection of the columns consumers may see.

Runs unchanged as an AWS Glue job and as an EMR Serverless Spark job.
"""

import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source_path", required=True)
    parser.add_argument("--target_path", required=True)
    # Glue adds arguments of its own to the command line.
    arguments, _ = parser.parse_known_args()
    return arguments


def datasets_with_files(spark, location):
    """Names of the top-level prefixes of a location that contain files."""
    jvm = spark.sparkContext._jvm
    path = jvm.org.apache.hadoop.fs.Path(location)
    file_system = path.getFileSystem(spark.sparkContext._jsc.hadoopConfiguration())
    if not file_system.exists(path):
        return []
    names = []
    for status in file_system.listStatus(path):
        name = status.getPath().getName()
        if not status.isDirectory() or name.startswith(("_", ".")):
            continue
        if file_system.listFiles(status.getPath(), True).hasNext():
            names.append(name)
    return sorted(names)


def main():
    arguments = parse_arguments()
    source = arguments.source_path.rstrip("/")
    target = arguments.target_path.rstrip("/")
    spark = SparkSession.builder.appName("processed-to-curated").getOrCreate()

    datasets = datasets_with_files(spark, source)
    if not datasets:
        print(f"No datasets found in {source}, nothing to do")

    for dataset in datasets:
        records = spark.read.parquet(f"{source}/{dataset}/")
        business_columns = [column for column in records.columns if column != "processed_at"]
        curated = records.dropna(how="all", subset=business_columns).withColumn("curated_at", F.current_timestamp())
        curated.write.mode("overwrite").parquet(f"{target}/{dataset}/")
        print(f"Curated dataset {dataset}")

    spark.stop()


if __name__ == "__main__":
    main()
