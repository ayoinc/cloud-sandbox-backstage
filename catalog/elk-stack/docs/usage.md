# ELK Stack Usage Guide

## Docker Compose Deployment

### Development (Single Node)

```yaml
# docker-compose.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q 'green\\|yellow'"]
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.12.0
    container_name: logstash
    ports:
      - "5044:5044"
      - "9600:9600"
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
    environment:
      - "LS_JAVA_OPTS=-Xms512m -Xmx512m"
    depends_on:
      elasticsearch:
        condition: service_healthy

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      elasticsearch:
        condition: service_healthy

volumes:
  elasticsearch_data:
```

### Production (3-Node Cluster with Security)

```yaml
# docker-compose.yml
version: '3.8'

services:
  setup:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    user: "0"
    command: >
      bash -c '
        if [ ! -f config/certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f config/certs/certs.zip ]; then
          echo "Creating certs";
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key --dns es01,es02,es03,localhost --ip 127.0.0.1;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions";
        chown -R 1000:0 config/certs;
      '

  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=production
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es01/es01.key
      - xpack.security.http.ssl.certificate=certs/es01/es01.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es01/es01.key
      - xpack.security.transport.ssl.certificate=certs/es01/es01.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - es01_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - elk

  es02:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=production
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es02/es02.key
      - xpack.security.http.ssl.certificate=certs/es02/es02.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es02/es02.key
      - xpack.security.transport.ssl.certificate=certs/es02/es02.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - es02_data:/usr/share/elasticsearch/data
    networks:
      - elk

  es03:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=production
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es03/es03.key
      - xpack.security.http.ssl.certificate=certs/es03/es03.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es03/es03.key
      - xpack.security.transport.ssl.certificate=certs/es03/es03.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - es03_data:/usr/share/elasticsearch/data
    networks:
      - elk

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=https://es01:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
      - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
    volumes:
      - certs:/usr/share/kibana/config/certs
    ports:
      - "5601:5601"
    networks:
      - elk
    depends_on:
      - es01

volumes:
  certs:
  es01_data:
  es02_data:
  es03_data:

networks:
  elk:
    driver: bridge
```

## Kubernetes Deployment

### ECK Operator Installation

```bash
# Install ECK CRDs and operator
kubectl create -f https://download.elastic.co/downloads/eck/2.11.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.11.0/operator.yaml

# Verify operator
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

### Elasticsearch Cluster

```yaml
# elasticsearch.yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: production
  namespace: elastic-system
spec:
  version: 8.12.0
  nodeSets:
    - name: master
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
                  memory: 2Gi
                  cpu: 1
                limits:
                  memory: 4Gi
                  cpu: 2
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes: ["ReadWriteOnce"]
            storageClassName: standard
            resources:
              requests:
                storage: 10Gi

    - name: data
      count: 3
      config:
        node.roles: ["data", "ingest"]
      podTemplate:
        spec:
          containers:
            - name: elasticsearch
              resources:
                requests:
                  memory: 4Gi
                  cpu: 2
                limits:
                  memory: 8Gi
                  cpu: 4
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes: ["ReadWriteOnce"]
            storageClassName: standard
            resources:
              requests:
                storage: 100Gi
  http:
    tls:
      selfSignedCertificate:
        disabled: false
```

### Kibana Deployment

```yaml
# kibana.yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: production
  namespace: elastic-system
spec:
  version: 8.12.0
  count: 2
  elasticsearchRef:
    name: production
  http:
    tls:
      selfSignedCertificate:
        disabled: false
  podTemplate:
    spec:
      containers:
        - name: kibana
          resources:
            requests:
              memory: 1Gi
              cpu: 500m
            limits:
              memory: 2Gi
              cpu: 1000m
```

## Elasticsearch Queries

### Basic Queries

```bash
# Search all documents
GET /logs-*/_search
{
  "query": {
    "match_all": {}
  },
  "size": 10
}

# Full-text search
GET /logs-*/_search
{
  "query": {
    "match": {
      "message": "error connection timeout"
    }
  }
}

# Phrase match
GET /logs-*/_search
{
  "query": {
    "match_phrase": {
      "message": "connection refused"
    }
  }
}

# Boolean query
GET /logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "level": "ERROR" } }
      ],
      "filter": [
        { "range": { "@timestamp": { "gte": "now-1h" } } },
        { "term": { "service": "api-gateway" } }
      ],
      "must_not": [
        { "match": { "message": "healthcheck" } }
      ]
    }
  }
}

# Wildcard query
GET /logs-*/_search
{
  "query": {
    "wildcard": {
      "host.keyword": "web-*"
    }
  }
}
```

### Aggregations

```bash
# Terms aggregation (top values)
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "error_by_service": {
      "terms": {
        "field": "service.keyword",
        "size": 10
      }
    }
  }
}

# Date histogram
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "logs_over_time": {
      "date_histogram": {
        "field": "@timestamp",
        "fixed_interval": "1h"
      },
      "aggs": {
        "by_level": {
          "terms": {
            "field": "level.keyword"
          }
        }
      }
    }
  }
}

# Percentiles
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "response_time_percentiles": {
      "percentiles": {
        "field": "response_time",
        "percents": [50, 90, 95, 99]
      }
    }
  }
}

# Cardinality (unique count)
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "unique_users": {
      "cardinality": {
        "field": "user_id.keyword"
      }
    }
  }
}
```

### Index Management

```bash
# Create index with mappings
PUT /logs-production
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "index.lifecycle.name": "logs-policy"
  },
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "level": { "type": "keyword" },
      "message": { "type": "text" },
      "service": { "type": "keyword" },
      "host": { "type": "keyword" },
      "response_time": { "type": "float" },
      "user_id": { "type": "keyword" },
      "request_id": { "type": "keyword" },
      "metadata": { "type": "object", "enabled": false }
    }
  }
}

# Reindex
POST /_reindex
{
  "source": {
    "index": "logs-old"
  },
  "dest": {
    "index": "logs-new"
  }
}

# Delete by query
POST /logs-*/_delete_by_query
{
  "query": {
    "range": {
      "@timestamp": {
        "lt": "now-90d"
      }
    }
  }
}

# Refresh index
POST /logs-production/_refresh

# Force merge
POST /logs-production/_forcemerge?max_num_segments=1
```

## Python Client Example

```python
# pip install elasticsearch

from elasticsearch import Elasticsearch
from datetime import datetime

# Connect
es = Elasticsearch(
    ["https://localhost:9200"],
    basic_auth=("elastic", "password"),
    ca_certs="/path/to/ca.crt"
)

# Check connection
print(es.info())

# Index a document
doc = {
    "@timestamp": datetime.utcnow().isoformat(),
    "level": "INFO",
    "message": "User logged in",
    "service": "auth-service",
    "user_id": "user123"
}

resp = es.index(index="logs-production", document=doc)
print(f"Indexed: {resp['_id']}")

# Bulk indexing
from elasticsearch.helpers import bulk

def generate_docs():
    for i in range(1000):
        yield {
            "_index": "logs-production",
            "_source": {
                "@timestamp": datetime.utcnow().isoformat(),
                "level": "INFO",
                "message": f"Log message {i}",
                "service": "batch-service"
            }
        }

success, failed = bulk(es, generate_docs())
print(f"Indexed {success} documents, {failed} failures")

# Search
results = es.search(
    index="logs-*",
    query={
        "bool": {
            "must": [{"match": {"level": "ERROR"}}],
            "filter": [{"range": {"@timestamp": {"gte": "now-1h"}}}]
        }
    },
    size=100
)

for hit in results['hits']['hits']:
    print(f"{hit['_source']['@timestamp']}: {hit['_source']['message']}")

# Aggregation
agg_results = es.search(
    index="logs-*",
    size=0,
    aggs={
        "errors_by_service": {
            "terms": {"field": "service.keyword", "size": 10}
        }
    }
)

for bucket in agg_results['aggregations']['errors_by_service']['buckets']:
    print(f"{bucket['key']}: {bucket['doc_count']} errors")
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Cluster RED | Unassigned primary shards | Check disk space, node health |
| Cluster YELLOW | Unassigned replica shards | Add nodes or reduce replicas |
| High heap usage | Memory pressure | Increase heap, optimize queries |
| Slow queries | Large result sets, complex aggs | Add filters, use pagination |
| Indexing slow | Refresh too frequent | Increase refresh_interval |
| Node not joining | Network/discovery issues | Check discovery settings, firewall |
| Split brain | Improper master config | Use odd number of masters |
| Disk watermark | High disk usage | Add space or delete old indices |

### Diagnostic Commands

```bash
# Cluster health
curl -XGET "localhost:9200/_cluster/health?pretty"

# Node stats
curl -XGET "localhost:9200/_nodes/stats?pretty"

# Pending tasks
curl -XGET "localhost:9200/_cluster/pending_tasks?pretty"

# Shard allocation
curl -XGET "localhost:9200/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason"

# Explain unassigned shards
curl -XGET "localhost:9200/_cluster/allocation/explain?pretty"

# Hot threads
curl -XGET "localhost:9200/_nodes/hot_threads"

# Index recovery
curl -XGET "localhost:9200/_cat/recovery?v"

# Task list
curl -XGET "localhost:9200/_tasks?detailed=true&actions=*search*"
```

### Recovery Procedures

```bash
# Reroute unassigned shards
POST /_cluster/reroute
{
  "commands": [
    {
      "allocate_stale_primary": {
        "index": "logs-2024.01.15",
        "shard": 0,
        "node": "es-node-1",
        "accept_data_loss": true
      }
    }
  ]
}

# Cancel pending tasks
POST /_tasks/task_id/_cancel

# Clear cache
POST /_cache/clear

# Rolling restart
# 1. Disable shard allocation
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}

# 2. Perform sync flush
POST /_flush/synced

# 3. Restart node
# 4. Wait for node to rejoin
# 5. Re-enable allocation
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}
```

## Best Practices

### Index Design

1. **Use time-based indices** - `logs-YYYY.MM.dd` for easy lifecycle management
2. **Right-size shards** - Target 10-50GB per shard
3. **Use aliases** - Abstract index names for seamless rollovers
4. **Define mappings explicitly** - Avoid dynamic mapping overhead
5. **Use keyword for exact matches** - text for full-text search

### Query Performance

1. **Use filters over queries** - Filters are cached
2. **Limit result size** - Use pagination with search_after
3. **Avoid wildcards at start** - `*error` is expensive
4. **Pre-aggregate where possible** - Use transforms
5. **Monitor slow logs** - Enable and review regularly

### Security Checklist

- [ ] Enable TLS for HTTP and transport
- [ ] Change default passwords
- [ ] Use role-based access control
- [ ] Enable audit logging
- [ ] Configure field-level security
- [ ] Use API keys over passwords
- [ ] Restrict network access

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and configuration details
