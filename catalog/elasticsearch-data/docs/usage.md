# Elasticsearch Usage Guide

## Indexing Workflow

```d2
direction: down

title: Elasticsearch Indexing Workflow {
  shape: text
  near: top-center
  style.font-size: 24
  style.bold: true
}

# Document Submission
client: Client Application {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"
  shape: rectangle
  icon: https://icons.terrastruct.com/tech%2Fdesktop.svg
  
  doc: Document {
    shape: page
    style.fill: "#bbdefb"
  }
}

# Coordinating Node
coord: Coordinating Node {
  style.fill: "#fff3e0"
  style.stroke: "#ef6c00"
  
  route: Routing {
    shape: diamond
    style.fill: "#ffb74d"
    
    hash: "_id hash % shards" {
      shape: text
      style.font-size: 12
    }
  }
}

# Pipeline Processing
pipeline: Ingest Pipeline {
  style.fill: "#f3e5f5"
  style.stroke: "#7b1fa2"
  
  steps: Processing Steps {
    style.fill: "#e1bee7"
    
    parse: "1. Parse" {shape: step; style.fill: "#ce93d8"}
    transform: "2. Transform" {shape: step; style.fill: "#ba68c8"}
    enrich: "3. Enrich" {shape: step; style.fill: "#ab47bc"}
    validate: "4. Validate" {shape: step; style.fill: "#9c27b0"; style.font-color: white}
    
    parse -> transform -> enrich -> validate
  }
}

# Primary Shard
primary: Primary Shard {
  style.fill: "#e8f5e9"
  style.stroke: "#2e7d32"
  
  write: Write to Translog {
    shape: cylinder
    style.fill: "#81c784"
  }
  
  index: Index in Memory {
    shape: hexagon
    style.fill: "#66bb6a"
    style.font-color: white
  }
  
  segment: Create Segment {
    shape: document
    style.fill: "#4caf50"
    style.font-color: white
  }
  
  write -> index: "1. Durability"
  index -> segment: "2. Refresh (1s)"
}

# Replica Shards
replicas: Replica Shards {
  style.fill: "#fce4ec"
  style.stroke: "#c2185b"
  
  r1: Replica 1 {
    shape: cylinder
    style.fill: "#f48fb1"
  }
  r2: Replica 2 {
    shape: cylinder
    style.fill: "#f48fb1"
  }
}

# Response
response: Response to Client {
  shape: document
  style.fill: "#c8e6c9"
  style.stroke: "#2e7d32"
  
  ack: "_id, _version, result: created" {
    shape: text
    style.font-size: 12
  }
}

# Flow
client -> coord: "PUT /index/_doc/1\n{...}"
coord -> pipeline: "If pipeline specified"
pipeline -> coord
coord.route -> primary: "Route to shard"
primary -> replicas.r1: "Replicate" {style.stroke: "#e91e63"; style.stroke-dash: 3}
primary -> replicas.r2: "Replicate" {style.stroke: "#e91e63"; style.stroke-dash: 3}
replicas -> coord: "ACK" {style.stroke: "#4caf50"}
coord -> response: "Success"
response -> client
```

## Prerequisites

- Docker and Docker Compose (for containerized deployment)
- 4GB+ RAM per node (16GB+ recommended for production)
- SSD storage recommended
- curl or Kibana Dev Tools for API access

## Deployment with Docker Compose

### 3-Node Cluster

```yaml
# docker-compose.yml
version: '3.8'

services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=docker-cluster
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es01-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - elastic
    healthcheck:
      test: ["CMD-SHELL", "curl -s -u elastic:${ELASTIC_PASSWORD:-changeme} http://localhost:9200/_cluster/health | grep -q 'green\\|yellow'"]
      interval: 30s
      timeout: 10s
      retries: 5

  es02:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=docker-cluster
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es02-data:/usr/share/elasticsearch/data
    networks:
      - elastic

  es03:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=docker-cluster
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es03-data:/usr/share/elasticsearch/data
    networks:
      - elastic

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://es01:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD:-changeme}
    ports:
      - "5601:5601"
    networks:
      - elastic
    depends_on:
      - es01

volumes:
  es01-data:
  es02-data:
  es03-data:

networks:
  elastic:
    driver: bridge
```

### Kubernetes Deployment (ECK Operator)

```yaml
# elasticsearch-cluster.yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: production
  namespace: elastic-system
spec:
  version: 8.12.0
  nodeSets:
  - name: masters
    count: 3
    config:
      node.roles: ["master"]
      xpack.ml.enabled: false
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 4Gi
              cpu: 1
            limits:
              memory: 4Gi
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
        storageClassName: fast-ssd

  - name: hot
    count: 3
    config:
      node.roles: ["data_hot", "data_content", "ingest"]
      node.attr.data: hot
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 16Gi
              cpu: 4
            limits:
              memory: 16Gi
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 500Gi
        storageClassName: fast-ssd

  - name: warm
    count: 2
    config:
      node.roles: ["data_warm"]
      node.attr.data: warm
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 8Gi
              cpu: 2
            limits:
              memory: 8Gi
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 2Ti
        storageClassName: standard
```

## Query Examples

### Basic Search

```json
// Match query (full-text search)
GET /products/_search
{
  "query": {
    "match": {
      "description": "wireless bluetooth headphones"
    }
  }
}

// Multi-match query
GET /products/_search
{
  "query": {
    "multi_match": {
      "query": "laptop gaming",
      "fields": ["name^3", "description", "category"],
      "type": "best_fields"
    }
  }
}

// Term query (exact match)
GET /products/_search
{
  "query": {
    "term": {
      "status": "active"
    }
  }
}

// Range query
GET /orders/_search
{
  "query": {
    "range": {
      "created_at": {
        "gte": "2024-01-01",
        "lt": "2024-02-01"
      }
    }
  }
}
```

### Boolean Queries

```json
// Complex boolean query
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "description": "laptop" } }
      ],
      "filter": [
        { "term": { "status": "active" } },
        { "range": { "price": { "gte": 500, "lte": 2000 } } }
      ],
      "should": [
        { "term": { "brand": "apple" } },
        { "term": { "brand": "dell" } }
      ],
      "minimum_should_match": 1,
      "must_not": [
        { "term": { "category": "refurbished" } }
      ]
    }
  }
}
```

### Aggregations

```json
// Bucket and metric aggregations
GET /orders/_search
{
  "size": 0,
  "aggs": {
    "orders_by_status": {
      "terms": {
        "field": "status",
        "size": 10
      },
      "aggs": {
        "total_revenue": {
          "sum": { "field": "total_amount" }
        },
        "avg_order_value": {
          "avg": { "field": "total_amount" }
        }
      }
    },
    "monthly_sales": {
      "date_histogram": {
        "field": "created_at",
        "calendar_interval": "month"
      },
      "aggs": {
        "revenue": {
          "sum": { "field": "total_amount" }
        }
      }
    },
    "price_ranges": {
      "range": {
        "field": "total_amount",
        "ranges": [
          { "to": 50 },
          { "from": 50, "to": 100 },
          { "from": 100, "to": 500 },
          { "from": 500 }
        ]
      }
    }
  }
}

// Percentiles and stats
GET /response_times/_search
{
  "size": 0,
  "aggs": {
    "latency_percentiles": {
      "percentiles": {
        "field": "response_time",
        "percents": [50, 90, 95, 99]
      }
    },
    "latency_stats": {
      "extended_stats": {
        "field": "response_time"
      }
    }
  }
}
```

### Full-Text Search with Highlighting

```json
GET /articles/_search
{
  "query": {
    "match": {
      "content": "elasticsearch performance tuning"
    }
  },
  "highlight": {
    "fields": {
      "content": {
        "fragment_size": 150,
        "number_of_fragments": 3,
        "pre_tags": ["<em>"],
        "post_tags": ["</em>"]
      }
    }
  },
  "_source": ["title", "author", "published_at"],
  "size": 10
}
```

### Vector Search (kNN)

```json
// Index with dense vector
PUT /products/_doc/1
{
  "name": "Wireless Headphones",
  "embedding": [0.1, 0.2, 0.3, ...]  // 768 dimensions
}

// kNN search
GET /products/_search
{
  "knn": {
    "field": "embedding",
    "query_vector": [0.15, 0.22, 0.28, ...],
    "k": 10,
    "num_candidates": 100
  },
  "_source": ["name", "description"]
}

// Hybrid search (kNN + keyword)
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "category": "electronics" } }
      ]
    }
  },
  "knn": {
    "field": "embedding",
    "query_vector": [0.15, 0.22, 0.28, ...],
    "k": 10,
    "num_candidates": 100,
    "boost": 0.5
  },
  "size": 10
}
```

## Indexing Data

### Single Document

```bash
# Index a document
PUT /products/_doc/1
{
  "name": "iPhone 15 Pro",
  "description": "Latest Apple smartphone with A17 chip",
  "price": 999.99,
  "category": "smartphones",
  "tags": ["apple", "5g", "premium"],
  "created_at": "2024-01-15T10:30:00Z"
}

# Auto-generate ID
POST /products/_doc
{
  "name": "Samsung Galaxy S24",
  "price": 899.99
}
```

### Bulk Indexing

```bash
POST _bulk
{"index": {"_index": "products", "_id": "1"}}
{"name": "Product 1", "price": 100}
{"index": {"_index": "products", "_id": "2"}}
{"name": "Product 2", "price": 200}
{"update": {"_index": "products", "_id": "1"}}
{"doc": {"price": 150}}
{"delete": {"_index": "products", "_id": "3"}}
```

### Ingest Pipelines

```json
// Create pipeline
PUT _ingest/pipeline/logs-pipeline
{
  "description": "Process log entries",
  "processors": [
    {
      "grok": {
        "field": "message",
        "patterns": ["%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}"]
      }
    },
    {
      "date": {
        "field": "timestamp",
        "formats": ["ISO8601"],
        "target_field": "@timestamp"
      }
    },
    {
      "remove": {
        "field": "timestamp"
      }
    },
    {
      "set": {
        "field": "processed_at",
        "value": "{{_ingest.timestamp}}"
      }
    }
  ]
}

// Index with pipeline
POST /logs/_doc?pipeline=logs-pipeline
{
  "message": "2024-01-15T10:30:00.000Z ERROR Connection refused to database"
}
```

## Client Libraries

### Python (elasticsearch-py)

```python
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk

# Connect
es = Elasticsearch(
    ["https://localhost:9200"],
    basic_auth=("elastic", "password"),
    verify_certs=False
)

# Check cluster health
print(es.cluster.health())

# Index document
es.index(
    index="products",
    id=1,
    document={
        "name": "Laptop",
        "price": 999.99,
        "category": "electronics"
    }
)

# Search
response = es.search(
    index="products",
    query={
        "match": {
            "name": "laptop"
        }
    }
)

for hit in response["hits"]["hits"]:
    print(hit["_source"])

# Bulk indexing
def generate_docs():
    for i in range(1000):
        yield {
            "_index": "products",
            "_id": i,
            "_source": {
                "name": f"Product {i}",
                "price": i * 10
            }
        }

bulk(es, generate_docs())
```

### Node.js (@elastic/elasticsearch)

```javascript
const { Client } = require('@elastic/elasticsearch');

const client = new Client({
  node: 'https://localhost:9200',
  auth: {
    username: 'elastic',
    password: 'password'
  },
  tls: {
    rejectUnauthorized: false
  }
});

// Index document
await client.index({
  index: 'products',
  id: '1',
  document: {
    name: 'Laptop',
    price: 999.99
  }
});

// Search
const response = await client.search({
  index: 'products',
  query: {
    match: { name: 'laptop' }
  }
});

console.log(response.hits.hits);

// Bulk indexing
const operations = [];
for (let i = 0; i < 1000; i++) {
  operations.push({ index: { _index: 'products', _id: i } });
  operations.push({ name: `Product ${i}`, price: i * 10 });
}

await client.bulk({ operations });
```

## Index Management

### Create/Update Index

```bash
# Create index with settings
PUT /logs-2024.01
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "refresh_interval": "30s",
    "index.mapping.total_fields.limit": 2000
  },
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "message": { "type": "text" }
    }
  }
}

# Update settings (dynamic only)
PUT /logs-2024.01/_settings
{
  "number_of_replicas": 2,
  "refresh_interval": "1s"
}

# Add mapping field
PUT /logs-2024.01/_mapping
{
  "properties": {
    "new_field": { "type": "keyword" }
  }
}
```

### Reindex

```json
POST _reindex
{
  "source": {
    "index": "old-index",
    "query": {
      "range": {
        "created_at": {
          "gte": "2024-01-01"
        }
      }
    }
  },
  "dest": {
    "index": "new-index",
    "pipeline": "my-pipeline"
  }
}
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Cluster RED | Unassigned primary shards | Check disk space, node health; `GET _cluster/allocation/explain` |
| Cluster YELLOW | Missing replica shards | Add nodes, reduce replicas for single-node clusters |
| High heap usage | Large aggregations, field data | Add more memory, use `doc_values`, paginate results |
| Slow queries | Missing indexes, large result sets | Add keyword fields, use filters, limit size |
| Bulk indexing slow | Small batch size, sync refresh | Increase batch to 5-15MB, disable refresh during bulk |
| Circuit breaker trips | Query too large | Reduce aggregation cardinality, add memory |
| Mapping explosion | Dynamic mapping with unique fields | Set `dynamic: strict`, control field count |

### Diagnostic Commands

```bash
# Cluster allocation explanation
GET _cluster/allocation/explain

# Pending tasks
GET _cluster/pending_tasks

# Hot threads
GET _nodes/hot_threads

# Task management
GET _tasks?detailed=true&actions=*search*

# Shard stores (for recovery issues)
GET /my-index/_shard_stores

# Slow logs (configure in index settings)
PUT /my-index/_settings
{
  "index.search.slowlog.threshold.query.warn": "10s",
  "index.search.slowlog.threshold.fetch.warn": "1s",
  "index.indexing.slowlog.threshold.index.warn": "10s"
}
```

## Best Practices

### Indexing

1. **Use bulk API** for multiple documents (5-15MB batches)
2. **Disable refresh** during bulk loads (`refresh_interval: -1`)
3. **Use auto-generated IDs** when possible for better performance
4. **Set explicit mappings** - avoid dynamic mapping in production

### Querying

1. **Use filters** for exact matches (cached, faster)
2. **Paginate with `search_after`** instead of `from/size` for deep pagination
3. **Limit returned fields** with `_source` filtering
4. **Use `doc_values`** for sorting/aggregations (default for keyword/numeric)

### Cluster Operations

1. **Use dedicated master nodes** for clusters > 10 nodes
2. **Size shards to 10-50GB** each
3. **Set replica count** based on availability requirements
4. **Enable ILM** for time-series data management
5. **Regular snapshots** to S3/GCS/Azure

### Security Checklist

- [ ] Enable TLS for HTTP and transport
- [ ] Use strong passwords for built-in users
- [ ] Create specific roles for applications
- [ ] Use API keys instead of user credentials in apps
- [ ] Enable audit logging
- [ ] Restrict network access to cluster ports
