# Splunk Enterprise Usage Guide

## Docker Compose Deployment

### Single Instance (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  splunk:
    image: splunk/splunk:latest
    container_name: splunk
    hostname: splunk
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD:-changeme123}
      - SPLUNK_HEC_TOKEN=${SPLUNK_HEC_TOKEN}
    ports:
      - "8000:8000"    # Web UI
      - "8088:8088"    # HEC
      - "8089:8089"    # Management API
      - "9997:9997"    # Forwarder receiving
    volumes:
      - splunk-var:/opt/splunk/var
      - splunk-etc:/opt/splunk/etc
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  splunk-var:
  splunk-etc:
```

### Distributed Deployment

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Cluster Manager
  cluster-manager:
    image: splunk/splunk:latest
    hostname: cluster-manager
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD}
      - SPLUNK_ROLE=splunk_cluster_master
      - SPLUNK_CLUSTER_MASTER_URL=cluster-manager
      - SPLUNK_INDEXER_REPLICATION_FACTOR=2
      - SPLUNK_INDEXER_SEARCH_FACTOR=2
    ports:
      - "8000:8000"

  # Indexers
  indexer1:
    image: splunk/splunk:latest
    hostname: indexer1
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD}
      - SPLUNK_ROLE=splunk_indexer
      - SPLUNK_CLUSTER_MASTER_URL=cluster-manager
    depends_on:
      - cluster-manager

  indexer2:
    image: splunk/splunk:latest
    hostname: indexer2
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD}
      - SPLUNK_ROLE=splunk_indexer
      - SPLUNK_CLUSTER_MASTER_URL=cluster-manager
    depends_on:
      - cluster-manager

  # Search Head
  search-head:
    image: splunk/splunk:latest
    hostname: search-head
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD}
      - SPLUNK_ROLE=splunk_search_head
      - SPLUNK_CLUSTER_MASTER_URL=cluster-manager
      - SPLUNK_INDEXER_URL=indexer1,indexer2
    ports:
      - "8001:8000"
    depends_on:
      - indexer1
      - indexer2

  # Universal Forwarder
  forwarder:
    image: splunk/universalforwarder:latest
    hostname: forwarder
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD}
      - SPLUNK_FORWARD_SERVER=indexer1:9997,indexer2:9997
    volumes:
      - /var/log:/var/log:ro
```

## Kubernetes Deployment

### Splunk Operator Installation

```bash
# Install Splunk Operator
kubectl apply -f https://github.com/splunk/splunk-operator/releases/download/2.5.0/splunk-operator-cluster.yaml

# Create namespace
kubectl create namespace splunk

# Create license and admin password secrets
kubectl create secret generic splunk-license \
  --namespace splunk \
  --from-file=license.xml

kubectl create secret generic splunk-admin-secret \
  --namespace splunk \
  --from-literal=password=${SPLUNK_PASSWORD}
```

### Standalone Instance

```yaml
# standalone.yaml
apiVersion: enterprise.splunk.com/v4
kind: Standalone
metadata:
  name: standalone
  namespace: splunk
spec:
  replicas: 1
  defaults:
    splunk:
      conf:
        - file: inputs.conf
          app: system
          content:
            http:
              disabled: "false"
              port: "8088"
  volumes:
    - name: license
      secret:
        secretName: splunk-license
  licenseUrl: /mnt/licenses/license.xml
  etcVolumeStorageConfig:
    storageClassName: standard
    storageCapacity: 10Gi
  varVolumeStorageConfig:
    storageClassName: standard
    storageCapacity: 100Gi
```

### Indexer Cluster

```yaml
# indexer-cluster.yaml
apiVersion: enterprise.splunk.com/v4
kind: ClusterMaster
metadata:
  name: cluster-manager
  namespace: splunk
spec:
  defaults:
    splunk:
      cluster_manager:
        replication_factor: 2
        search_factor: 2
---
apiVersion: enterprise.splunk.com/v4
kind: IndexerCluster
metadata:
  name: indexer-cluster
  namespace: splunk
spec:
  replicas: 3
  clusterManagerRef:
    name: cluster-manager
  varVolumeStorageConfig:
    storageClassName: fast-ssd
    storageCapacity: 500Gi
  resources:
    requests:
      memory: 4Gi
      cpu: 2
    limits:
      memory: 8Gi
      cpu: 4
---
apiVersion: enterprise.splunk.com/v4
kind: SearchHeadCluster
metadata:
  name: search-head-cluster
  namespace: splunk
spec:
  replicas: 3
  clusterManagerRef:
    name: cluster-manager
```

## Universal Forwarder Deployment

### Linux Installation

```bash
#!/bin/bash
# install-forwarder.sh

SPLUNK_HOME="/opt/splunkforwarder"
SPLUNK_INDEXER="indexer1.example.com:9997,indexer2.example.com:9997"

# Download and install
wget -O splunkforwarder.tgz "https://download.splunk.com/products/universalforwarder/releases/9.2.0/linux/splunkforwarder-9.2.0-linux-x86_64.tgz"
tar -xzf splunkforwarder.tgz -C /opt

# Accept license and set admin password
$SPLUNK_HOME/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd changeme

# Configure outputs
cat > $SPLUNK_HOME/etc/system/local/outputs.conf << EOF
[tcpout]
defaultGroup = indexers

[tcpout:indexers]
server = ${SPLUNK_INDEXER}
useACK = true
EOF

# Configure inputs
cat > $SPLUNK_HOME/etc/system/local/inputs.conf << EOF
[default]
host = $(hostname)

[monitor:///var/log/syslog]
disabled = false
sourcetype = syslog
index = os

[monitor:///var/log/auth.log]
disabled = false
sourcetype = linux_secure
index = security
EOF

# Enable boot start
$SPLUNK_HOME/bin/splunk enable boot-start -user splunk

# Restart
$SPLUNK_HOME/bin/splunk restart
```

### Kubernetes DaemonSet

```yaml
# forwarder-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: splunk-forwarder
  namespace: splunk
spec:
  selector:
    matchLabels:
      app: splunk-forwarder
  template:
    metadata:
      labels:
        app: splunk-forwarder
    spec:
      containers:
        - name: splunk-forwarder
          image: splunk/universalforwarder:latest
          env:
            - name: SPLUNK_START_ARGS
              value: "--accept-license"
            - name: SPLUNK_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: splunk-admin-secret
                  key: password
            - name: SPLUNK_FORWARD_SERVER
              value: "indexer-cluster-indexer-service:9997"
          volumeMounts:
            - name: varlog
              mountPath: /var/log
              readOnly: true
            - name: containerlog
              mountPath: /var/lib/docker/containers
              readOnly: true
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: containerlog
          hostPath:
            path: /var/lib/docker/containers
```

## Dashboard Creation

### Simple XML Dashboard

```xml
<dashboard>
  <label>Application Performance</label>
  <row>
    <panel>
      <chart>
        <title>Requests per Minute</title>
        <search>
          <query>index=application | timechart span=1m count</query>
          <earliest>-1h</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">line</option>
      </chart>
    </panel>
    <panel>
      <single>
        <title>Error Rate</title>
        <search>
          <query>
            index=application 
            | stats count(eval(status>=500)) as errors, count as total 
            | eval error_rate=round(errors/total*100,2)
            | fields error_rate
          </query>
          <earliest>-1h</earliest>
        </search>
        <option name="colorBy">value</option>
        <option name="rangeColors">["0x53A051","0xF8BE34","0xDC4E41"]</option>
        <option name="rangeValues">[1,5]</option>
        <option name="useColors">1</option>
      </single>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Top Errors</title>
        <search>
          <query>
            index=application level=ERROR 
            | stats count by error_message 
            | sort -count 
            | head 10
          </query>
          <earliest>-24h</earliest>
        </search>
      </table>
    </panel>
  </row>
</dashboard>
```

## REST API Usage

```python
import requests
from requests.auth import HTTPBasicAuth

SPLUNK_URL = "https://localhost:8089"
USERNAME = "admin"
PASSWORD = "changeme"

# Create session
session = requests.Session()
session.auth = HTTPBasicAuth(USERNAME, PASSWORD)
session.verify = False  # For self-signed certs

# Run search
search_query = "search index=main | head 10"
response = session.post(
    f"{SPLUNK_URL}/services/search/jobs",
    data={
        "search": search_query,
        "output_mode": "json",
        "exec_mode": "blocking"
    }
)

job_sid = response.json()["sid"]

# Get results
results = session.get(
    f"{SPLUNK_URL}/services/search/jobs/{job_sid}/results",
    params={"output_mode": "json"}
)

for result in results.json()["results"]:
    print(result)

# Create saved search
session.post(
    f"{SPLUNK_URL}/servicesNS/admin/search/saved/searches",
    data={
        "name": "My Saved Search",
        "search": "index=main error | stats count",
        "cron_schedule": "*/15 * * * *",
        "is_scheduled": 1
    }
)
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No data from forwarder | Network/firewall | Check port 9997 connectivity |
| License violation | Exceeded daily limit | Add license or reduce ingestion |
| Slow searches | Large data volume | Use acceleration, narrow time range |
| HEC not receiving | Token invalid | Verify token and endpoint |
| Search head crash | Memory exhaustion | Increase memory, optimize searches |
| Bucket corruption | Disk issues | Run `splunk fsck` |

### Diagnostic Commands

```bash
# Check Splunk status
/opt/splunk/bin/splunk status

# View internal logs
tail -f /opt/splunk/var/log/splunk/splunkd.log

# Check license usage
/opt/splunk/bin/splunk list license

# Validate configuration
/opt/splunk/bin/splunk btool check

# Show cluster status
/opt/splunk/bin/splunk show cluster-status

# List forwarders
/opt/splunk/bin/splunk list forward-server

# Debug data inputs
/opt/splunk/bin/splunk list monitor

# REST API health
curl -k -u admin:changeme https://localhost:8089/services/server/health
```

### Bucket Management

```bash
# List buckets
/opt/splunk/bin/splunk list index

# Check bucket integrity
/opt/splunk/bin/splunk fsck repair --index-name=main

# Rebuild metadata
/opt/splunk/bin/splunk rebuild myindex

# Clean old data
/opt/splunk/bin/splunk clean eventdata -index main -f
```

## Best Practices

### Indexing Strategy

1. **Use index-time field extraction sparingly** - Prefer search-time
2. **Set appropriate retention** - Balance cost vs. compliance
3. **Use summary indexing** - For long-term trending
4. **Implement data models** - For accelerated searches
5. **Monitor license usage** - Stay within limits

### Search Optimization

1. **Be specific with time** - Use narrow time ranges
2. **Filter early** - Use indexed fields first
3. **Avoid wildcards** - Especially leading wildcards
4. **Use tstats** - For data model searches
5. **Limit returned fields** - Use `| fields` command

### Security Checklist

- [ ] Change default admin password
- [ ] Enable TLS for all communication
- [ ] Configure role-based access
- [ ] Enable audit logging
- [ ] Implement network segmentation
- [ ] Use HEC tokens per source
- [ ] Enable SSO/SAML

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Configuration and SPL
