"""Raw zone to processed zone.

Every top-level prefix of the source location is one dataset. Each dataset is
read in its source format, exact duplicate records are removed and the result
replaces the dataset of the same name in the target location as Parquet.

The job reads the whole dataset on every run. Replace it with an incremental
load when the raw zone grows beyond what one run should read.

Runs unchanged as an AWS Glue job and as an EMR Serverless Spark job.
"""

import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source_path", required=True)
    parser.add_argument("--target_path", required=True)
    parser.add_argument("--source_format", default="json")
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
    spark = SparkSession.builder.appName("raw-to-processed").getOrCreate()

    datasets = datasets_with_files(spark, source)
    if not datasets:
        print(f"No datasets found in {source}, nothing to do")

    for dataset in datasets:
        records = (
            spark.read.format(arguments.source_format)
            .option("recursiveFileLookup", "true")
            .load(f"{source}/{dataset}/")
        )
        processed = records.dropDuplicates().withColumn("processed_at", F.current_timestamp())
        processed.write.mode("overwrite").parquet(f"{target}/{dataset}/")
        print(f"Processed dataset {dataset}")

    spark.stop()


if __name__ == "__main__":
    main()
