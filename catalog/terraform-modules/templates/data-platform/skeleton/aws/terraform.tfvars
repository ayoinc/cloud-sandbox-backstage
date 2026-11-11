# Values chosen in the portal when this repository was created.

project_name = "${{ values.projectName }}"
environment  = "${{ values.environment }}"
region       = "${{ values.awsRegion }}"

enable_data_lake        = ${{ values.enableDataLake | dump }}
data_lake_storage_class = "${{ values.dataLakeStorageClass }}"
enable_data_catalog     = ${{ values.enableDataCatalog | dump }}

enable_data_warehouse = ${{ values.enableDataWarehouse | dump }}
warehouse_size        = "${{ values.warehouseSize }}"

enable_etl_pipelines = ${{ values.enableEtlPipelines | dump }}
etl_engine           = "${{ values.etlEngine }}"
enable_orchestration = ${{ values.enableOrchestration | dump }}

enable_streaming          = ${{ values.enableStreaming | dump }}
streaming_retention_hours = ${{ values.streamingRetention }}

enable_bi_tools    = ${{ values.enableBiTools | dump }}
enable_ml_platform = ${{ values.enableMlPlatform | dump }}

enable_encryption     = ${{ values.enableEncryption | dump }}
enable_data_lineage   = ${{ values.enableDataLineage | dump }}
enable_access_control = ${{ values.enableAccessControl | dump }}
