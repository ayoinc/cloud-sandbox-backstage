# Splunk Enterprise Overview

## Architecture Deep Dive

### Indexer Cluster

```d2
direction: down

title: Indexer Cluster {
  shape: text
  near: top-center
  style.font-size: 24
}

manager: Cluster Manager {
  shape: hexagon
  style.fill: "#9C27B0"
  style.font-color: white
}

indexers: Indexers {
  style.fill: "#FFF3E0"

  idx1: Indexer 1 {
    style.fill: "#FF9800"
    style.font-color: white

    bucket_a: Bucket A (Primary) {shape: cylinder}
    bucket_b: Bucket B (Replica) {shape: cylinder}
  }

  idx2: Indexer 2 {
    style.fill: "#FF9800"
    style.font-color: white

    bucket_a: Bucket A (Replica) {shape: cylinder}
    bucket_c: Bucket C (Primary) {shape: cylinder}
  }

  idx3: Indexer 3 {
    style.fill: "#FF9800"
    style.font-color: white

    bucket_b: Bucket B (Primary) {shape: cylinder}
    bucket_c: Bucket C (Replica) {shape: cylinder}
  }
}

config: Replication Factor: 2\nSearch Factor: 2 {
  shape: text
  style.font-size: 12
}

manager -> indexers.idx1: Manage
manager -> indexers.idx2: Manage
manager -> indexers.idx3: Manage
```

### Search Head Cluster

```d2
direction: down

title: Search Head Cluster {
  shape: text
  near: top-center
  style.font-size: 24
}

deployer: Deployer {
  shape: hexagon
  style.fill: "#9C27B0"
  style.font-color: white
}

searchheads: Search Heads {
  style.fill: "#FCE4EC"

  sh1: Search Head 1\n(Captain) {
    shape: hexagon
    style.fill: "#E91E63"
    style.font-color: white
  }

  sh2: Search Head 2\n(Member) {
    shape: hexagon
    style.fill: "#E91E63"
    style.font-color: white
  }

  sh3: Search Head 3\n(Member) {
    shape: hexagon
    style.fill: "#E91E63"
    style.font-color: white
  }
}

lb: Load Balancer (Round Robin) {
  shape: rectangle
  style.fill: "#4CAF50"
  style.font-color: white
}

deployer -> searchheads: Push Apps
searchheads -> lb: Serve
```

## Configuration

### Server Configuration (server.conf)

```ini
# /opt/splunk/etc/system/local/server.conf

[general]
serverName = splunk-indexer-01
pass4SymmKey = <cluster_secret>

[sslConfig]
sslPassword = <ssl_password>
serverCert = $SPLUNK_HOME/etc/auth/server.pem
sslRootCAPath = $SPLUNK_HOME/etc/auth/ca.pem

[clustering]
mode = peer
manager_uri = https://cluster-manager:8089
pass4SymmKey = <cluster_secret>

[replication_port://9887]
disabled = false
```

### Inputs Configuration (inputs.conf)

```ini
# /opt/splunk/etc/system/local/inputs.conf

[default]
host = splunk-indexer-01

[splunktcp://9997]
disabled = false
connection_host = dns

[http://mytoken]
disabled = false
token = <HEC_TOKEN>
index = main
sourcetype = json

[monitor:///var/log/syslog]
disabled = false
index = os
sourcetype = syslog

[monitor:///var/log/app/*.log]
disabled = false
index = application
sourcetype = app:json
crcSalt = <SOURCE>

# Multi-line events
[monitor:///var/log/app/java.log]
disabled = false
index = application
sourcetype = java
BREAK_ONLY_BEFORE = ^\d{4}-\d{2}-\d{2}

# Scripted input
[script:///opt/splunk/bin/scripts/metrics.sh]
disabled = false
interval = 60
sourcetype = custom:metrics
index = metrics
```

### Outputs Configuration (outputs.conf)

```ini
# /opt/splunkforwarder/etc/system/local/outputs.conf

[tcpout]
defaultGroup = primary_indexers

[tcpout:primary_indexers]
server = indexer1:9997,indexer2:9997,indexer3:9997
autoLB = true
autoLBFrequency = 30
forceTimebasedAutoLB = true
useACK = true

[tcpout:primary_indexers]
sslCertPath = $SPLUNK_HOME/etc/auth/server.pem
sslRootCAPath = $SPLUNK_HOME/etc/auth/ca.pem
sslPassword = <password>
sslVerifyServerCert = true

# Indexer discovery
[indexer_discovery:clustered_indexers]
manager_uri = https://cluster-manager:8089
pass4SymmKey = <cluster_secret>

[tcpout:clustered_group]
indexerDiscovery = clustered_indexers
```

### Props and Transforms (Data Parsing)

```ini
# props.conf
[source::/var/log/app/*.log]
TIME_FORMAT = %Y-%m-%d %H:%M:%S,%3N
TIME_PREFIX = ^
MAX_TIMESTAMP_LOOKAHEAD = 30
SHOULD_LINEMERGE = false
LINE_BREAKER = ([\r\n]+)
TRUNCATE = 100000

[app:json]
INDEXED_EXTRACTIONS = json
KV_MODE = json
TIME_FORMAT = %Y-%m-%dT%H:%M:%S.%3N%Z
TIME_PREFIX = "timestamp"\s*:\s*"
TRANSFORMS-mask-secrets = mask-api-keys,mask-passwords

# transforms.conf
[mask-api-keys]
REGEX = (api[_-]?key["']?\s*[:=]\s*["']?)([A-Za-z0-9]{20,})
FORMAT = $1<MASKED>
DEST_KEY = _raw

[mask-passwords]
REGEX = (password["']?\s*[:=]\s*["']?)([^"'\s]+)
FORMAT = $1<MASKED>
DEST_KEY = _raw
```

## SPL (Search Processing Language)

### Basic Searches

```spl
# Simple search
index=main error

# Time range
index=main error earliest=-1h latest=now

# Field search
index=main status=500 host="web-*"

# Wildcards
index=main source="/var/log/*" NOT debug

# Boolean operators
index=main (error OR exception) AND NOT healthcheck

# Field extraction with rex
index=main | rex field=_raw "user=(?<username>\w+)"

# Stats commands
index=main | stats count by host
index=main | stats avg(response_time) as avg_response by endpoint
index=main | stats count, avg(duration), max(duration), min(duration) by status

# Timechart
index=main | timechart span=5m count by status

# Top values
index=main | top 10 host
index=main | rare 10 error_code
```

### Advanced Searches

```spl
# Transaction (group related events)
index=main | transaction session_id maxspan=30m

# Join
index=orders | join type=left order_id [search index=customers]

# Subsearch
index=main [search index=errors | return 100 user_id]

# Lookup enrichment
index=main | lookup user_info user_id OUTPUT department, manager

# Event correlation
index=security sourcetype=firewall action=blocked
| stats count by src_ip
| where count > 100

# Anomaly detection
index=main | timechart span=1h count
| predict count as predicted_count
| eval anomaly=if(count > predicted_count*1.5, 1, 0)

# Machine learning (MLTK)
| inputlookup server_metrics.csv
| fit DensityFunction cpu_usage into cpu_model
| apply cpu_model

# Accelerated data model
| tstats count from datamodel=Web where Web.status>=500 by Web.dest

# Splunk Enterprise Security notable
| `notable` | search severity=critical | table time, rule_name, src, dest
```

## HTTP Event Collector (HEC)

### Configuration

```ini
# inputs.conf
[http]
disabled = false
port = 8088
enableSSL = true
dedicatedIoThreads = 2

[http://application_events]
token = <generated-token>
disabled = false
index = application
sourcetype = app:events
indexes = application,main

[http://metrics]
token = <metrics-token>
disabled = false
index = metrics
sourcetype = metrics:json
```

### Sending Data

```python
import requests
import json

hec_url = "https://splunk:8088/services/collector/event"
headers = {
    "Authorization": "Splunk <HEC_TOKEN>",
    "Content-Type": "application/json"
}

# Single event
event = {
    "event": {
        "message": "User login successful",
        "user": "john.doe",
        "action": "login"
    },
    "time": 1705312800,
    "host": "web-server-01",
    "source": "auth-service",
    "sourcetype": "app:auth",
    "index": "application"
}

response = requests.post(hec_url, headers=headers, data=json.dumps(event), verify=False)

# Batch events
events = [
    {"event": {"action": "click", "page": "/home"}},
    {"event": {"action": "click", "page": "/products"}},
    {"event": {"action": "purchase", "amount": 99.99}}
]

batch_data = "\n".join([json.dumps(e) for e in events])
response = requests.post(hec_url, headers=headers, data=batch_data, verify=False)

# Metrics
metric_event = {
    "time": 1705312800,
    "event": "metric",
    "source": "server-01",
    "host": "server-01",
    "fields": {
        "metric_name:cpu.usage": 75.5,
        "metric_name:memory.used": 8192,
        "_value": 75.5,
        "cpu": "cpu0"
    }
}
```

## Alerting

### Alert Configuration

```ini
# savedsearches.conf
[High Error Rate Alert]
search = index=application sourcetype=app:logs level=ERROR | stats count | where count > 100
dispatch.earliest_time = -5m
dispatch.latest_time = now
cron_schedule = */5 * * * *
enableSched = 1
alert.track = 1
alert.severity = 4
alert_condition = search count > 0
alert.suppress = 1
alert.suppress.period = 1h
action.email = 1
action.email.to = oncall@example.com
action.email.subject = High Error Rate Detected
action.webhook = 1
action.webhook.param.url = https://hooks.slack.com/services/xxx
```

## Security

### Role-Based Access Control

```ini
# authorize.conf
[role_analyst]
importRoles = user
srchIndexesAllowed = main;application;security
srchIndexesDefault = main
cumulativeSrchJobsQuota = 10
rtSrchJobsQuota = 5
srchDiskQuota = 1000
srchJobsQuota = 20

[role_admin]
importRoles = admin
srchIndexesAllowed = *
srchIndexesDefault = main
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
