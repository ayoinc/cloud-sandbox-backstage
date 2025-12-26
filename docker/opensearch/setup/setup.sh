#!/bin/sh
# OpenSearch Setup Script
# Creates index templates, index patterns, visualizations, and dashboards for Backstage

set -e

OPENSEARCH_HOST="${OPENSEARCH_HOST:-opensearch:9200}"
DASHBOARDS_HOST="${DASHBOARDS_HOST:-opensearch-dashboards:5601}"

echo "============================================"
echo "OpenSearch Stack Setup"
echo "============================================"
echo ""

# Wait for OpenSearch to be ready
echo "Waiting for OpenSearch..."
until curl -s "http://${OPENSEARCH_HOST}/_cluster/health" | grep -q '"status":"green"\|"status":"yellow"'; do
  echo "  OpenSearch not ready, waiting..."
  sleep 5
done
echo "OpenSearch is ready!"

# Wait for Dashboards to be ready
echo "Waiting for OpenSearch Dashboards..."
until curl -s "http://${DASHBOARDS_HOST}/api/status" | grep -q '"state":"green"'; do
  echo "  Dashboards not ready, waiting..."
  sleep 5
done
echo "OpenSearch Dashboards is ready!"

echo ""
echo "Creating index templates..."

# Backstage logs template
curl -s -X PUT "http://${OPENSEARCH_HOST}/_index_template/backstage-logs" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["backstage-*"],
    "priority": 100,
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.refresh_interval": "5s"
      },
      "mappings": {
        "properties": {
          "@timestamp": {"type": "date"},
          "message": {"type": "text", "fields": {"keyword": {"type": "keyword", "ignore_above": 2048}}},
          "level": {"type": "keyword"},
          "service": {"type": "keyword"},
          "plugin": {"type": "keyword"},
          "container_name": {"type": "keyword"},
          "log_type": {"type": "keyword"},
          "environment": {"type": "keyword"},
          "user": {"type": "keyword"},
          "action": {"type": "keyword"},
          "entityRef": {"type": "keyword"},
          "taskId": {"type": "keyword"},
          "method": {"type": "keyword"},
          "url": {"type": "keyword"},
          "path": {"type": "keyword"},
          "status": {"type": "integer"},
          "duration_ms": {"type": "float"},
          "type": {"type": "keyword"},
          "httpVersion": {"type": "keyword"},
          "userAgent": {"type": "keyword"}
        }
      }
    }
  }' && echo " - backstage-logs template created"

# Nginx logs template
curl -s -X PUT "http://${OPENSEARCH_HOST}/_index_template/nginx-logs" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["nginx-*"],
    "priority": 100,
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "@timestamp": {"type": "date"},
          "remote_addr": {"type": "ip"},
          "remote_user": {"type": "keyword"},
          "method": {"type": "keyword"},
          "path": {"type": "keyword"},
          "status": {"type": "integer"},
          "body_bytes_sent": {"type": "long"},
          "http_referer": {"type": "keyword"},
          "http_user_agent": {"type": "text"},
          "container_name": {"type": "keyword"},
          "log_type": {"type": "keyword"}
        }
      }
    }
  }' && echo " - nginx-logs template created"

# Infrastructure logs template
curl -s -X PUT "http://${OPENSEARCH_HOST}/_index_template/infrastructure-logs" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["infrastructure-*"],
    "priority": 100,
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "@timestamp": {"type": "date"},
          "message": {"type": "text"},
          "level": {"type": "keyword"},
          "container_name": {"type": "keyword"},
          "log_type": {"type": "keyword"},
          "environment": {"type": "keyword"}
        }
      }
    }
  }' && echo " - infrastructure-logs template created"

# General logs template
curl -s -X PUT "http://${OPENSEARCH_HOST}/_index_template/general-logs" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["logs-*", "misc-*"],
    "priority": 50,
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "@timestamp": {"type": "date"},
          "message": {"type": "text"},
          "level": {"type": "keyword"},
          "container_name": {"type": "keyword"},
          "log_type": {"type": "keyword"}
        }
      }
    }
  }' && echo " - general-logs template created"

echo ""
echo "Creating ISM (Index State Management) policy..."

# Create ISM policy for log retention
curl -s -X PUT "http://${OPENSEARCH_HOST}/_plugins/_ism/policies/logs-retention-policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "description": "Log retention policy - delete after 14 days",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [],
          "transitions": [
            {
              "state_name": "warm",
              "conditions": {
                "min_index_age": "3d"
              }
            }
          ]
        },
        {
          "name": "warm",
          "actions": [
            {
              "replica_count": {
                "number_of_replicas": 0
              }
            }
          ],
          "transitions": [
            {
              "state_name": "delete",
              "conditions": {
                "min_index_age": "14d"
              }
            }
          ]
        },
        {
          "name": "delete",
          "actions": [
            {
              "delete": {}
            }
          ],
          "transitions": []
        }
      ],
      "ism_template": [
        {
          "index_patterns": ["backstage-*", "nginx-*", "infrastructure-*", "logs-*", "misc-*"],
          "priority": 100
        }
      ]
    }
  }' && echo " - logs-retention-policy created"

echo ""
echo "Creating index patterns in Dashboards..."

# Create index patterns
for pattern in "backstage-*" "nginx-*" "infrastructure-*" "logs-*"; do
  curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/index-pattern/${pattern}" \
    -H "osd-xsrf: true" \
    -H "Content-Type: application/json" \
    -d "{
      \"attributes\": {
        \"title\": \"${pattern}\",
        \"timeFieldName\": \"@timestamp\"
      }
    }" 2>/dev/null && echo " - ${pattern} index pattern created" || echo " - ${pattern} index pattern (may already exist)"
done

# Create an "All Logs" pattern
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/index-pattern/all-logs" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "backstage-*,nginx-*,infrastructure-*,logs-*",
      "timeFieldName": "@timestamp"
    }
  }' 2>/dev/null && echo " - all-logs index pattern created" || echo " - all-logs (may already exist)"

echo ""
echo "Setting default index pattern..."
curl -s -X POST "http://${DASHBOARDS_HOST}/api/opensearch-dashboards/settings/defaultIndex" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{"value": "backstage-*"}' 2>/dev/null || true

echo ""
echo "Creating visualizations..."

# =============================================
# VISUALIZATIONS
# =============================================

# 1. Log Volume Over Time (Area Chart)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/log-volume-over-time" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Log Volume Over Time",
      "visState": "{\"title\":\"Log Volume Over Time\",\"type\":\"area\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"date_histogram\",\"params\":{\"field\":\"@timestamp\",\"timeRange\":{\"from\":\"now-24h\",\"to\":\"now\"},\"useNormalizedOpenSearchInterval\":true,\"scaleMetricValues\":false,\"interval\":\"auto\",\"drop_partials\":false,\"min_doc_count\":1,\"extended_bounds\":{}},\"schema\":\"segment\"},{\"id\":\"3\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"container_name\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":10,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"group\"}],\"params\":{\"type\":\"area\",\"grid\":{\"categoryLines\":false},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\"},\"labels\":{\"show\":true,\"filter\":true,\"truncate\":100},\"title\":{}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\",\"mode\":\"normal\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"Count\"}}],\"seriesParams\":[{\"show\":true,\"type\":\"area\",\"mode\":\"stacked\",\"data\":{\"label\":\"Count\",\"id\":\"1\"},\"valueAxis\":\"ValueAxis-1\",\"drawLinesBetweenPoints\":true,\"lineWidth\":2,\"showCircles\":true}],\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"times\":[],\"addTimeMarker\":false,\"palette\":{\"type\":\"palette\",\"name\":\"default\"},\"isVislibVis\":true,\"detailedTooltip\":true,\"fittingFunction\":\"zero\"}}",
      "uiStateJSON": "{}",
      "description": "Log volume over time by container",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Log Volume Over Time visualization created"

# 2. Log Levels Distribution (Pie Chart)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/log-levels-distribution" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Log Levels Distribution",
      "visState": "{\"title\":\"Log Levels Distribution\",\"type\":\"pie\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"level\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":10,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"segment\"}],\"params\":{\"type\":\"pie\",\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"isDonut\":true,\"labels\":{\"show\":true,\"values\":true,\"last_level\":true,\"truncate\":100},\"palette\":{\"type\":\"palette\",\"name\":\"default\"}}}",
      "uiStateJSON": "{}",
      "description": "Distribution of log levels",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Log Levels Distribution visualization created"

# 3. HTTP Status Codes (Pie Chart)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/http-status-codes" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "HTTP Status Codes",
      "visState": "{\"title\":\"HTTP Status Codes\",\"type\":\"pie\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"status\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":20,\"otherBucket\":true,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"segment\"}],\"params\":{\"type\":\"pie\",\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"isDonut\":true,\"labels\":{\"show\":true,\"values\":true,\"last_level\":true,\"truncate\":100}}}",
      "uiStateJSON": "{}",
      "description": "HTTP status code distribution",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - HTTP Status Codes visualization created"

# 4. Top API Endpoints (Horizontal Bar)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/top-api-endpoints" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Top API Endpoints",
      "visState": "{\"title\":\"Top API Endpoints\",\"type\":\"horizontal_bar\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"url\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":15,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"segment\"}],\"params\":{\"type\":\"horizontal_bar\",\"grid\":{\"categoryLines\":false},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"left\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":200},\"title\":{}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"BottomAxis-1\",\"type\":\"value\",\"position\":\"bottom\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\",\"mode\":\"normal\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":true,\"truncate\":100},\"title\":{\"text\":\"Count\"}}],\"seriesParams\":[{\"show\":true,\"type\":\"histogram\",\"mode\":\"normal\",\"data\":{\"label\":\"Count\",\"id\":\"1\"},\"valueAxis\":\"ValueAxis-1\",\"drawLinesBetweenPoints\":true,\"lineWidth\":2,\"showCircles\":true}],\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"times\":[],\"addTimeMarker\":false}}",
      "uiStateJSON": "{}",
      "description": "Most accessed API endpoints",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Top API Endpoints visualization created"

# 5. Errors Over Time (Line Chart)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/errors-over-time" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Errors Over Time",
      "visState": "{\"title\":\"Errors Over Time\",\"type\":\"line\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"date_histogram\",\"params\":{\"field\":\"@timestamp\",\"timeRange\":{\"from\":\"now-24h\",\"to\":\"now\"},\"useNormalizedOpenSearchInterval\":true,\"scaleMetricValues\":false,\"interval\":\"auto\",\"drop_partials\":false,\"min_doc_count\":1,\"extended_bounds\":{}},\"schema\":\"segment\"}],\"params\":{\"type\":\"line\",\"grid\":{\"categoryLines\":false},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\"},\"labels\":{\"show\":true,\"filter\":true,\"truncate\":100},\"title\":{}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\",\"mode\":\"normal\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"Error Count\"}}],\"seriesParams\":[{\"show\":true,\"type\":\"line\",\"mode\":\"normal\",\"data\":{\"label\":\"Count\",\"id\":\"1\"},\"valueAxis\":\"ValueAxis-1\",\"drawLinesBetweenPoints\":true,\"lineWidth\":2,\"interpolate\":\"linear\",\"showCircles\":true}],\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"times\":[],\"addTimeMarker\":false}}",
      "uiStateJSON": "{}",
      "description": "Error logs over time",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"level: error OR level: warn\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Errors Over Time visualization created"

# 6. Container Logs Distribution (Pie)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/container-logs-distribution" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Container Logs Distribution",
      "visState": "{\"title\":\"Container Logs Distribution\",\"type\":\"pie\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"container_name\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":10,\"otherBucket\":true,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"segment\"}],\"params\":{\"type\":\"pie\",\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"isDonut\":true,\"labels\":{\"show\":true,\"values\":true,\"last_level\":true,\"truncate\":100}}}",
      "uiStateJSON": "{}",
      "description": "Log distribution by container",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "all-logs",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Container Logs Distribution visualization created"

# 7. Plugin Activity (Bar Chart)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/plugin-activity" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Plugin Activity",
      "visState": "{\"title\":\"Plugin Activity\",\"type\":\"histogram\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"plugin\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":15,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"segment\"}],\"params\":{\"type\":\"histogram\",\"grid\":{\"categoryLines\":false},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\"},\"labels\":{\"show\":true,\"filter\":true,\"truncate\":100,\"rotate\":45},\"title\":{}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\",\"mode\":\"normal\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"Count\"}}],\"seriesParams\":[{\"show\":true,\"type\":\"histogram\",\"mode\":\"normal\",\"data\":{\"label\":\"Count\",\"id\":\"1\"},\"valueAxis\":\"ValueAxis-1\",\"drawLinesBetweenPoints\":true,\"lineWidth\":2,\"showCircles\":true}],\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"times\":[],\"addTimeMarker\":false}}",
      "uiStateJSON": "{}",
      "description": "Backstage plugin log activity",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"plugin: *\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Plugin Activity visualization created"

# 8. Total Log Count (Metric)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/total-log-count" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Total Log Count",
      "visState": "{\"title\":\"Total Log Count\",\"type\":\"metric\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"}],\"params\":{\"addTooltip\":true,\"addLegend\":false,\"type\":\"metric\",\"metric\":{\"percentageMode\":false,\"useRanges\":false,\"colorSchema\":\"Green to Red\",\"metricColorMode\":\"None\",\"colorsRange\":[{\"from\":0,\"to\":10000}],\"labels\":{\"show\":true},\"invertColors\":false,\"style\":{\"bgFill\":\"#000\",\"bgColor\":false,\"labelColor\":false,\"subText\":\"\",\"fontSize\":60}}}}",
      "uiStateJSON": "{}",
      "description": "Total number of log entries",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "all-logs",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Total Log Count visualization created"

# 9. Error Count (Metric)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/error-count" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Error Count",
      "visState": "{\"title\":\"Error Count\",\"type\":\"metric\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"}],\"params\":{\"addTooltip\":true,\"addLegend\":false,\"type\":\"metric\",\"metric\":{\"percentageMode\":false,\"useRanges\":false,\"colorSchema\":\"Green to Red\",\"metricColorMode\":\"Background\",\"colorsRange\":[{\"from\":0,\"to\":10},{\"from\":10,\"to\":100},{\"from\":100,\"to\":1000}],\"labels\":{\"show\":true},\"invertColors\":false,\"style\":{\"bgFill\":\"#000\",\"bgColor\":true,\"labelColor\":false,\"subText\":\"errors\",\"fontSize\":60}}}}",
      "uiStateJSON": "{}",
      "description": "Count of error level logs",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"level: error\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "all-logs",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Error Count visualization created"

# 10. Nginx Request Rate (Line Chart)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/nginx-request-rate" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Nginx Request Rate",
      "visState": "{\"title\":\"Nginx Request Rate\",\"type\":\"line\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"date_histogram\",\"params\":{\"field\":\"@timestamp\",\"timeRange\":{\"from\":\"now-1h\",\"to\":\"now\"},\"useNormalizedOpenSearchInterval\":true,\"scaleMetricValues\":false,\"interval\":\"auto\",\"drop_partials\":false,\"min_doc_count\":1,\"extended_bounds\":{}},\"schema\":\"segment\"},{\"id\":\"3\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"method\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":5,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"group\"}],\"params\":{\"type\":\"line\",\"grid\":{\"categoryLines\":false},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\"},\"labels\":{\"show\":true,\"filter\":true,\"truncate\":100},\"title\":{}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\",\"mode\":\"normal\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"Requests\"}}],\"seriesParams\":[{\"show\":true,\"type\":\"line\",\"mode\":\"normal\",\"data\":{\"label\":\"Count\",\"id\":\"1\"},\"valueAxis\":\"ValueAxis-1\",\"drawLinesBetweenPoints\":true,\"lineWidth\":2,\"interpolate\":\"linear\",\"showCircles\":true}],\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"times\":[],\"addTimeMarker\":false}}",
      "uiStateJSON": "{}",
      "description": "Nginx requests per time bucket by method",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "nginx-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Nginx Request Rate visualization created"

# 11. TechDocs Build Status (Data Table)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/techdocs-build-status" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "TechDocs Build Status",
      "visState": "{\"title\":\"TechDocs Build Status\",\"type\":\"table\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"message.keyword\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":20,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"bucket\"}],\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMetricsAtAllLevels\":false,\"showTotal\":false,\"totalFunc\":\"sum\",\"percentageCol\":\"\"}}",
      "uiStateJSON": "{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}",
      "description": "TechDocs build messages",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"plugin: techdocs OR plugin: techdocs-queue\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - TechDocs Build Status visualization created"

# 12. Infrastructure Services Health (Tag Cloud)
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/visualization/infrastructure-services" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Infrastructure Services",
      "visState": "{\"title\":\"Infrastructure Services\",\"type\":\"tagcloud\",\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"params\":{},\"schema\":\"metric\"},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"params\":{\"field\":\"container_name\",\"orderBy\":\"1\",\"order\":\"desc\",\"size\":10,\"otherBucket\":false,\"otherBucketLabel\":\"Other\",\"missingBucket\":false,\"missingBucketLabel\":\"Missing\"},\"schema\":\"segment\"}],\"params\":{\"scale\":\"linear\",\"orientation\":\"single\",\"minFontSize\":18,\"maxFontSize\":72,\"showLabel\":true}}",
      "uiStateJSON": "{}",
      "description": "Infrastructure service log activity",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "infrastructure-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Infrastructure Services visualization created"

echo ""
echo "Creating saved searches..."

# =============================================
# SAVED SEARCHES
# =============================================

# 1. All Errors
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/search/all-errors" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "All Errors",
      "description": "All error level logs across all services",
      "columns": ["@timestamp", "container_name", "level", "message"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"level: error\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "all-logs",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - All Errors search created"

# 2. Backstage API Requests
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/search/backstage-api-requests" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Backstage API Requests",
      "description": "HTTP requests to Backstage API",
      "columns": ["@timestamp", "method", "url", "status", "userAgent"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"type: incomingRequest\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Backstage API Requests search created"

# 3. TechDocs Builds
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/search/techdocs-builds" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "TechDocs Builds",
      "description": "TechDocs build activity",
      "columns": ["@timestamp", "plugin", "message"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"plugin: techdocs OR plugin: techdocs-queue\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - TechDocs Builds search created"

# 4. Catalog Activity
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/search/catalog-activity" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Catalog Activity",
      "description": "Catalog plugin activity",
      "columns": ["@timestamp", "plugin", "message"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"plugin: catalog\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Catalog Activity search created"

# 5. Scaffolder Activity
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/search/scaffolder-activity" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Scaffolder Activity",
      "description": "Scaffolder/template activity",
      "columns": ["@timestamp", "plugin", "message", "taskId"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"plugin: scaffolder\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "backstage-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Scaffolder Activity search created"

# 6. Database Logs
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/search/database-logs" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Database Logs",
      "description": "PostgreSQL database logs",
      "columns": ["@timestamp", "log", "level"],
      "sort": [["@timestamp", "desc"]],
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"container_name: backstage-postgres\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
      }
    },
    "references": [
      {
        "id": "infrastructure-*",
        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
        "type": "index-pattern"
      }
    ]
  }' && echo " - Database Logs search created"

echo ""
echo "Creating dashboards..."

# =============================================
# DASHBOARDS
# =============================================

# 1. Main Overview Dashboard
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/dashboard/backstage-overview" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Backstage Overview",
      "description": "Main overview dashboard for Backstage Cloud Sandbox",
      "panelsJSON": "[{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":12,\"h\":8,\"i\":\"1\"},\"panelIndex\":\"1\",\"embeddableConfig\":{},\"panelRefName\":\"panel_1\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":12,\"y\":0,\"w\":12,\"h\":8,\"i\":\"2\"},\"panelIndex\":\"2\",\"embeddableConfig\":{},\"panelRefName\":\"panel_2\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":0,\"w\":12,\"h\":8,\"i\":\"3\"},\"panelIndex\":\"3\",\"embeddableConfig\":{},\"panelRefName\":\"panel_3\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":36,\"y\":0,\"w\":12,\"h\":8,\"i\":\"4\"},\"panelIndex\":\"4\",\"embeddableConfig\":{},\"panelRefName\":\"panel_4\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":8,\"w\":24,\"h\":12,\"i\":\"5\"},\"panelIndex\":\"5\",\"embeddableConfig\":{},\"panelRefName\":\"panel_5\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":8,\"w\":24,\"h\":12,\"i\":\"6\"},\"panelIndex\":\"6\",\"embeddableConfig\":{},\"panelRefName\":\"panel_6\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":20,\"w\":24,\"h\":12,\"i\":\"7\"},\"panelIndex\":\"7\",\"embeddableConfig\":{},\"panelRefName\":\"panel_7\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":20,\"w\":24,\"h\":12,\"i\":\"8\"},\"panelIndex\":\"8\",\"embeddableConfig\":{},\"panelRefName\":\"panel_8\"}]",
      "optionsJSON": "{\"useMargins\":true,\"hidePanelTitles\":false}",
      "timeRestore": true,
      "timeTo": "now",
      "timeFrom": "now-24h",
      "refreshInterval": {
        "pause": false,
        "value": 30000
      },
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    },
    "references": [
      {"id": "total-log-count", "name": "panel_1", "type": "visualization"},
      {"id": "error-count", "name": "panel_2", "type": "visualization"},
      {"id": "log-levels-distribution", "name": "panel_3", "type": "visualization"},
      {"id": "container-logs-distribution", "name": "panel_4", "type": "visualization"},
      {"id": "log-volume-over-time", "name": "panel_5", "type": "visualization"},
      {"id": "errors-over-time", "name": "panel_6", "type": "visualization"},
      {"id": "top-api-endpoints", "name": "panel_7", "type": "visualization"},
      {"id": "plugin-activity", "name": "panel_8", "type": "visualization"}
    ]
  }' && echo " - Backstage Overview dashboard created"

# 2. Backstage Application Dashboard
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/dashboard/backstage-application" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Backstage Application",
      "description": "Detailed Backstage application monitoring",
      "panelsJSON": "[{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":12,\"i\":\"1\"},\"panelIndex\":\"1\",\"embeddableConfig\":{},\"panelRefName\":\"panel_1\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":0,\"w\":24,\"h\":12,\"i\":\"2\"},\"panelIndex\":\"2\",\"embeddableConfig\":{},\"panelRefName\":\"panel_2\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":12,\"w\":24,\"h\":12,\"i\":\"3\"},\"panelIndex\":\"3\",\"embeddableConfig\":{},\"panelRefName\":\"panel_3\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":12,\"w\":24,\"h\":12,\"i\":\"4\"},\"panelIndex\":\"4\",\"embeddableConfig\":{},\"panelRefName\":\"panel_4\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":24,\"w\":48,\"h\":12,\"i\":\"5\"},\"panelIndex\":\"5\",\"embeddableConfig\":{},\"panelRefName\":\"panel_5\"}]",
      "optionsJSON": "{\"useMargins\":true,\"hidePanelTitles\":false}",
      "timeRestore": true,
      "timeTo": "now",
      "timeFrom": "now-24h",
      "refreshInterval": {
        "pause": false,
        "value": 30000
      },
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    },
    "references": [
      {"id": "log-volume-over-time", "name": "panel_1", "type": "visualization"},
      {"id": "http-status-codes", "name": "panel_2", "type": "visualization"},
      {"id": "plugin-activity", "name": "panel_3", "type": "visualization"},
      {"id": "top-api-endpoints", "name": "panel_4", "type": "visualization"},
      {"id": "techdocs-build-status", "name": "panel_5", "type": "visualization"}
    ]
  }' && echo " - Backstage Application dashboard created"

# 3. Infrastructure Dashboard
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/dashboard/infrastructure" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Infrastructure",
      "description": "Infrastructure services monitoring (Postgres, Redis, MinIO)",
      "panelsJSON": "[{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":12,\"i\":\"1\"},\"panelIndex\":\"1\",\"embeddableConfig\":{},\"panelRefName\":\"panel_1\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":0,\"w\":24,\"h\":12,\"i\":\"2\"},\"panelIndex\":\"2\",\"embeddableConfig\":{},\"panelRefName\":\"panel_2\"}]",
      "optionsJSON": "{\"useMargins\":true,\"hidePanelTitles\":false}",
      "timeRestore": true,
      "timeTo": "now",
      "timeFrom": "now-24h",
      "refreshInterval": {
        "pause": false,
        "value": 30000
      },
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    },
    "references": [
      {"id": "infrastructure-services", "name": "panel_1", "type": "visualization"},
      {"id": "log-levels-distribution", "name": "panel_2", "type": "visualization"}
    ]
  }' && echo " - Infrastructure dashboard created"

# 4. Nginx Dashboard
curl -s -X POST "http://${DASHBOARDS_HOST}/api/saved_objects/dashboard/nginx" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "Nginx Access Logs",
      "description": "Nginx web server access log analysis",
      "panelsJSON": "[{\"version\":\"2.11.1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":12,\"i\":\"1\"},\"panelIndex\":\"1\",\"embeddableConfig\":{},\"panelRefName\":\"panel_1\"},{\"version\":\"2.11.1\",\"gridData\":{\"x\":24,\"y\":0,\"w\":24,\"h\":12,\"i\":\"2\"},\"panelIndex\":\"2\",\"embeddableConfig\":{},\"panelRefName\":\"panel_2\"}]",
      "optionsJSON": "{\"useMargins\":true,\"hidePanelTitles\":false}",
      "timeRestore": true,
      "timeTo": "now",
      "timeFrom": "now-1h",
      "refreshInterval": {
        "pause": false,
        "value": 10000
      },
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    },
    "references": [
      {"id": "nginx-request-rate", "name": "panel_1", "type": "visualization"},
      {"id": "http-status-codes", "name": "panel_2", "type": "visualization"}
    ]
  }' && echo " - Nginx dashboard created"

echo ""
echo "============================================"
echo "OpenSearch Stack Setup Complete!"
echo "============================================"
echo ""
echo "Access Points:"
echo "  OpenSearch:            http://localhost:9200"
echo "  OpenSearch Dashboards: http://localhost:5601"
echo ""
echo "Index Patterns:"
echo "  - backstage-*      (Backstage application logs)"
echo "  - nginx-*          (Nginx access logs)"  
echo "  - infrastructure-* (Postgres, Redis, MinIO logs)"
echo "  - logs-*           (Other Docker container logs)"
echo "  - all-logs         (All logs combined)"
echo ""
echo "Dashboards:"
echo "  - Backstage Overview    (Main overview)"
echo "  - Backstage Application (Detailed app monitoring)"
echo "  - Infrastructure        (Database, Cache, Storage)"
echo "  - Nginx Access Logs     (Web server traffic)"
echo ""
echo "Saved Searches:"
echo "  - All Errors"
echo "  - Backstage API Requests"
echo "  - TechDocs Builds"
echo "  - Catalog Activity"
echo "  - Scaffolder Activity"
echo "  - Database Logs"
echo ""
