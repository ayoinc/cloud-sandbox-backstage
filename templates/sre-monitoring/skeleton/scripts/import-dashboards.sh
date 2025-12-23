#!/bin/bash
# Import Grafana dashboards via API
# Generated for: ${{ values.name }}

set -e

GRAFANA_URL="${GRAFANA_URL:-${{ values.grafanaUrl }}}"
GRAFANA_API_KEY="${GRAFANA_API_KEY:-}"
DASHBOARD_DIR="${DASHBOARD_DIR:-./dashboards}"

if [ -z "$GRAFANA_API_KEY" ]; then
    echo "Error: GRAFANA_API_KEY environment variable is required"
    exit 1
fi

echo "Importing dashboards to Grafana at $GRAFANA_URL"

# Create or get folder ID
FOLDER_NAME="${{ values.name }}"
FOLDER_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAFANA_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"$FOLDER_NAME\"}" \
    "$GRAFANA_URL/api/folders" 2>/dev/null || true)

FOLDER_ID=$(echo "$FOLDER_RESPONSE" | jq -r '.id // empty')

if [ -z "$FOLDER_ID" ]; then
    # Folder might already exist, try to get it
    FOLDER_RESPONSE=$(curl -s \
        -H "Authorization: Bearer $GRAFANA_API_KEY" \
        "$GRAFANA_URL/api/folders")
    FOLDER_ID=$(echo "$FOLDER_RESPONSE" | jq -r ".[] | select(.title==\"$FOLDER_NAME\") | .id")
fi

echo "Using folder ID: $FOLDER_ID"

# Import each dashboard
for dashboard_file in "$DASHBOARD_DIR"/*.json; do
    if [ -f "$dashboard_file" ]; then
        dashboard_name=$(basename "$dashboard_file" .json)
        echo "Importing dashboard: $dashboard_name"
        
        # Prepare the import payload
        dashboard_json=$(cat "$dashboard_file")
        import_payload=$(jq -n \
            --argjson dashboard "$dashboard_json" \
            --argjson folderId "$FOLDER_ID" \
            '{
                dashboard: $dashboard,
                folderId: $folderId,
                overwrite: true,
                message: "Imported via automation"
            }')
        
        # Import the dashboard
        response=$(curl -s -X POST \
            -H "Authorization: Bearer $GRAFANA_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$import_payload" \
            "$GRAFANA_URL/api/dashboards/db")
        
        status=$(echo "$response" | jq -r '.status // "success"')
        if [ "$status" = "success" ] || [ -z "$status" ]; then
            echo "  Successfully imported: $dashboard_name"
        else
            echo "  Failed to import: $dashboard_name"
            echo "  Response: $response"
        fi
    fi
done

echo "Dashboard import complete!"
