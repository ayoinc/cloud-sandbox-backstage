"""Converts newline-delimited JSON files of the raw zone into Parquet files in the processed zone.

The Dataproc workflow template of this stack runs this job. Replace it with the
transformations of your pipeline, or add more steps to the template.
"""

import argparse

from pyspark.sql import SparkSession


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, help="Location of the JSON files, for example gs://bucket/landing/")
    parser.add_argument("--target", required=True, help="Location the Parquet files are written to")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("raw-to-processed").getOrCreate()
    spark.read.json(args.source).write.mode("overwrite").parquet(args.target)
    spark.stop()


if __name__ == "__main__":
    main()
