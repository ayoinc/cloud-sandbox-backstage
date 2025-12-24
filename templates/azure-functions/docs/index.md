# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Functions App provides serverless compute using the **${{ values.runtimeStack }}** runtime for the **${{ values.environment }}** environment.

## Architecture

```d2
direction: right

client: Client {
  shape: person
}

azure: Azure {
  rg: Resource Group {
    func: Function App {
      shape: hexagon
      style.fill: "#0078D4"
    }

    storage: Storage Account {
      shape: cylinder
      style.fill: "#0078D4"
    }

    plan: Service Plan {
      shape: rectangle
      style.fill: "#0078D4"
    }

    insights: Application Insights {
      shape: rectangle
      style.fill: "#68217A"
    }
  }

  monitor: Azure Monitor {
    shape: rectangle
    style.fill: "#0078D4"
  }
}

triggers: Event Sources {
  http: HTTP Triggers {
    shape: rectangle
  }

  queue: Queue Triggers {
    shape: queue
  }

  timer: Timer Triggers {
    shape: rectangle
  }

  blob: Blob Triggers {
    shape: cylinder
  }
}

outputs: Outputs {
  database: Database {
    shape: cylinder
  }

  api: External APIs {
    shape: rectangle
  }

  events: Event Hub {
    shape: queue
  }
}

# Connections
client -> azure.rg.func: HTTPS
triggers.http -> azure.rg.func
triggers.queue -> azure.rg.func
triggers.timer -> azure.rg.func
triggers.blob -> azure.rg.func

azure.rg.func -> azure.rg.storage: State & Triggers
azure.rg.plan -> azure.rg.func: Hosts
azure.rg.func -> azure.rg.insights: Telemetry
azure.rg.insights -> azure.monitor: Aggregates

azure.rg.func -> outputs.database
azure.rg.func -> outputs.api
azure.rg.func -> outputs.events
```

## Configuration

| Setting              | Value                            |
| -------------------- | -------------------------------- |
| Runtime Stack        | ${{ values.runtimeStack }}       |
| Runtime Version      | ${{ values.runtimeVersion }}     |
| Hosting Plan         | ${{ values.skuTier }}            |
| Storage Tier         | ${{ values.storageAccountTier }} |
| Location             | ${{ values.location }}           |
| Environment          | ${{ values.environment }}        |
| Application Insights | ${{ values.enableAppInsights }}  |

## Features

- **Event-Driven**: Trigger functions from HTTP, queues, timers, blobs, and more
- **Auto-Scaling**: Scale automatically based on demand
- **Managed Identity**: Secure access to Azure resources without secrets
- **Application Insights**: Built-in monitoring and telemetry
- **Durable Functions**: Stateful workflows and orchestrations

## Trigger Types

### HTTP Triggers

Invoke functions via HTTP requests:

```bash
curl https://func-${{ values.name }}-${{ values.environment }}.azurewebsites.net/api/hello
```

### Timer Triggers

Run functions on a schedule using CRON expressions:

```json
{
  "schedule": "0 */5 * * * *",
  "runOnStartup": false
}
```

### Queue Triggers

Process messages from Azure Storage Queues:

```json
{
  "queueName": "my-queue",
  "connection": "AzureWebJobsStorage"
}
```

### Blob Triggers

React to blob storage events:

```json
{
  "path": "container/{name}",
  "connection": "AzureWebJobsStorage"
}
```

## Local Development

### Prerequisites

- Azure Functions Core Tools
- ${{ values.runtimeStack }} runtime installed
- Azure CLI

### Running Locally

```bash
# Install dependencies (varies by runtime)
# For Node.js:
npm install

# For Python:
pip install -r requirements.txt

# Start the function app locally
func start
```

### Testing

```bash
# Call a local HTTP function
curl http://localhost:7071/api/hello?name=World
```

## Deployment

### CI/CD Pipeline

Deployments are triggered automatically via GitHub Actions when pushing to `main`.

### Manual Deployment

```bash
# Deploy using Azure Functions Core Tools
func azure functionapp publish func-${{ values.name }}-${{ values.environment }}

# Or using Azure CLI
az functionapp deployment source config-zip \
  --resource-group rg-${{ values.name }}-${{ values.environment }} \
  --name func-${{ values.name }}-${{ values.environment }} \
  --src ./deployment.zip
```

## Environment Variables

Configure environment variables in Azure Portal or via Terraform:

```hcl
app_settings = {
  "MY_API_KEY"    = "@Microsoft.KeyVault(SecretUri=https://...)"
  "DATABASE_URL"  = "..."
  "FEATURE_FLAG"  = "true"
}
```

## Monitoring

### Application Insights

- View function invocations and failures
- Analyze performance metrics
- Set up alerts for errors and latency

### Log Analytics

```kusto
// Query function execution logs
traces
| where cloud_RoleName == "func-${{ values.name }}-${{ values.environment }}"
| order by timestamp desc
| take 100
```

## Security

### Managed Identity

The function app uses a system-assigned managed identity for secure access to Azure resources:

```hcl
# Grant access to Key Vault
resource "azurerm_key_vault_access_policy" "function" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.functions.principal_id

  secret_permissions = ["Get", "List"]
}
```

### Network Security

For Premium and Dedicated plans, enable VNET integration:

```hcl
# VNET integration (Premium/Dedicated only)
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = module.functions.function_app_id
  subnet_id      = azurerm_subnet.functions.id
}
```

## Owner

This resource is owned by **${{ values.owner }}**.
