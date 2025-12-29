# Multi-Cloud Data Platform

Production-ready data platform with data lake, warehouse, and ETL/ELT pipelines on AWS, Azure, or GCP.

## Architecture

```
                    ┌───────────────────────────────────────────────────────────────────────────┐
                    │                           Data Platform                                    │
                    │                                                                            │
    ┌───────────┐   │  ┌──────────────────────────────────────────────────────────────────────┐ │
    │  Data     │   │  │                         Data Ingestion                                │ │
    │  Sources  │───┼─▶│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                   │ │
    │  (APIs,   │   │  │  │   Batch     │  │  Streaming  │  │   Real-time │                   │ │
    │  Files,   │   │  │  │  (S3/GCS/   │  │  (Kinesis/  │  │  (Pub/Sub/  │                   │ │
    │  DBs)     │   │  │  │   Blob)     │  │  EventHubs) │  │   Kafka)    │                   │ │
    └───────────┘   │  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                   │ │
                    │  └─────────┼────────────────┼────────────────┼──────────────────────────┘ │
                    │            │                │                │                            │
                    │  ┌─────────▼────────────────▼────────────────▼──────────────────────────┐ │
                    │  │                       Data Lake                                       │ │
                    │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                │ │
                    │  │  │     Raw      │  │  Processed   │  │   Curated    │                │ │
                    │  │  │    Zone      │  │    Zone      │  │    Zone      │                │ │
                    │  │  │ (S3/ADLS/GCS)│  │ (S3/ADLS/GCS)│  │ (S3/ADLS/GCS)│                │ │
                    │  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                │ │
                    │  └─────────┼────────────────┼────────────────┼──────────────────────────┘ │
                    │            │                │                │                            │
                    │  ┌─────────▼────────────────▼────────────────▼──────────────────────────┐ │
                    │  │                    ETL/ELT Processing                                 │ │
                    │  │  ┌───────────────────────────────────────────────────────────────┐   │ │
                    │  │  │    Spark (EMR/Databricks/Dataproc) or Native (Glue/ADF/Dataflow)│  │ │
                    │  │  └───────────────────────────────────────────────────────────────┘   │ │
                    │  │  ┌───────────────────────────────────────────────────────────────┐   │ │
                    │  │  │       Orchestration (Step Functions / ADF / Composer)          │   │ │
                    │  │  └───────────────────────────────────────────────────────────────┘   │ │
                    │  └──────────────────────────────────────────────────────────────────────┘ │
                    │                                    │                                      │
                    │  ┌─────────────────────────────────▼────────────────────────────────────┐ │
                    │  │                       Data Warehouse                                  │ │
                    │  │              (Redshift / Synapse / BigQuery)                          │ │
                    │  └──────────────────────────────────────────────────────────────────────┘ │
                    │                                    │                                      │
                    │  ┌─────────────────────────────────▼────────────────────────────────────┐ │
                    │  │                       Data Catalog                                    │ │
                    │  │             (Glue Catalog / Purview / Data Catalog)                   │ │
                    │  └──────────────────────────────────────────────────────────────────────┘ │
                    │                                                                            │
                    │  ┌───────────────────────────┐  ┌───────────────────────────┐            │
    ┌───────────┐   │  │         BI Tools          │  │       ML Platform         │            │
    │ Analysts  │◀──┼──│  (QuickSight/PowerBI/     │  │   (SageMaker/AzureML/     │            │
    │   & DS    │   │  │         Looker)           │  │       Vertex AI)          │            │
    └───────────┘   │  └───────────────────────────┘  └───────────────────────────┘            │
                    └───────────────────────────────────────────────────────────────────────────┘
```

## Components by Cloud Provider

| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Object Storage | S3 | ADLS Gen2 | Cloud Storage |
| Data Catalog | Glue Catalog | Purview | Data Catalog |
| Data Warehouse | Redshift | Synapse Analytics | BigQuery |
| ETL (Native) | Glue | Data Factory | Dataflow |
| ETL (Spark) | EMR | Databricks | Dataproc |
| Orchestration | Step Functions | Data Factory | Cloud Composer |
| Streaming | Kinesis | Event Hubs | Pub/Sub |
| BI | QuickSight | Power BI | Looker |
| ML | SageMaker | Azure ML | Vertex AI |

## Data Zones

| Zone | Purpose | Data Quality |
|------|---------|--------------|
| Raw | Landing zone for source data | As-is from source |
| Processed | Cleaned and transformed data | Validated, deduplicated |
| Curated | Business-ready datasets | Aggregated, enriched |

## Usage

1. Select cloud provider
2. Enable data lake storage
3. Configure data warehouse
4. Choose ETL engine (Spark or Native)
5. Enable optional components (streaming, BI, ML)

## Outputs

- Data lake bucket/container URLs
- Data warehouse endpoint
- Data catalog ID
- Streaming endpoints (if enabled)
