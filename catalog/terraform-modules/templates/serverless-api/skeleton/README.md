# Multi-Cloud Serverless API

Production-ready serverless API with Lambda/Functions/Cloud Functions, API Gateway, and supporting services.

## Architecture

```
                              ┌───────────────────────────────────────────────────────────────┐
                              │                      Serverless API                            │
                              │                                                                │
    ┌───────────┐             │  ┌────────────────────────────────────────────────────────┐   │
    │           │   HTTPS     │  │                      WAF                                │   │
    │  Clients  │────────────▶│  │           (AWS WAF / Cloud Armor)                       │   │
    │           │             │  └────────────────────────┬───────────────────────────────┘   │
    └───────────┘             │                           │                                    │
                              │  ┌────────────────────────▼───────────────────────────────┐   │
                              │  │                   API Gateway                           │   │
                              │  │   (API Gateway / API Management / Cloud Endpoints)      │   │
                              │  │                                                         │   │
                              │  │  ┌─────────────────────────────────────────────────┐   │   │
                              │  │  │  Routes:                                         │   │   │
                              │  │  │  GET  /api/items     -> Function                 │   │   │
                              │  │  │  POST /api/items     -> Function                 │   │   │
                              │  │  │  GET  /api/items/:id -> Function                 │   │   │
                              │  │  │  ...                                             │   │   │
                              │  │  └─────────────────────────────────────────────────┘   │   │
                              │  └────────────────────────┬───────────────────────────────┘   │
                              │                           │                                    │
                              │  ┌────────────────────────▼───────────────────────────────┐   │
                              │  │                 Serverless Functions                    │   │
                              │  │        (Lambda / Azure Functions / Cloud Functions)     │   │
                              │  │                                                         │   │
                              │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │   │
                              │  │  │  Func   │  │  Func   │  │  Func   │  │  Func   │   │   │
                              │  │  │  (GET)  │  │ (POST)  │  │ (PUT)   │  │(DELETE) │   │   │
                              │  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘   │   │
                              │  └───────┼───────────┼───────────┼───────────┼─────────────┘   │
                              │          │           │           │           │                  │
                              │  ┌───────▼───────────▼───────────▼───────────▼─────────────┐   │
                              │  │                       Database                           │   │
                              │  │  (DynamoDB / Cosmos DB / Firestore / Aurora Serverless)  │   │
                              │  └─────────────────────────────────────────────────────────┘   │
                              │                                                                │
                              │  ┌───────────────────┐  ┌───────────────────┐                 │
                              │  │    Auth Provider   │  │   Object Storage  │                 │
                              │  │ (Cognito/AAD/      │  │ (S3/Blob/GCS)     │                 │
                              │  │  Firebase)         │  │                   │                 │
                              │  └───────────────────┘  └───────────────────┘                 │
                              │                                                                │
                              │  ┌─────────────────────────────────────────────────────────┐   │
                              │  │                   Observability                          │   │
                              │  │  (CloudWatch + X-Ray / App Insights / Cloud Trace)       │   │
                              │  └─────────────────────────────────────────────────────────┘   │
                              └───────────────────────────────────────────────────────────────┘
```

## Components by Cloud Provider

| Component      | AWS                     | Azure                     | GCP             |
| -------------- | ----------------------- | ------------------------- | --------------- |
| Functions      | Lambda                  | Azure Functions           | Cloud Functions |
| API Gateway    | API Gateway (HTTP/REST) | API Management            | Cloud Endpoints |
| Auth           | Cognito                 | Azure AD B2C              | Firebase Auth   |
| NoSQL DB       | DynamoDB                | Cosmos DB                 | Firestore       |
| SQL DB         | Aurora Serverless       | SQL Database (Serverless) | Cloud Spanner   |
| Object Storage | S3                      | Blob Storage              | Cloud Storage   |
| Cache          | ElastiCache             | Redis Cache               | Memorystore     |
| WAF            | AWS WAF                 | Azure WAF                 | Cloud Armor     |
| Tracing        | X-Ray                   | Application Insights      | Cloud Trace     |

## Supported Runtimes

| Runtime     | AWS Lambda      | Azure Functions     | Cloud Functions |
| ----------- | --------------- | ------------------- | --------------- |
| Node.js 20  | nodejs20.x      | node:20             | nodejs20        |
| Python 3.12 | python3.12      | python:3.12         | python312       |
| Go 1.21     | provided.al2023 | custom              | go121           |
| .NET 8      | dotnet8         | dotnet-isolated:8.0 | dotnet8         |
| Java 21     | java21          | java:21             | java21          |

## API Types

| Type     | Description             | Best For              |
| -------- | ----------------------- | --------------------- |
| HTTP API | Low latency, lower cost | Simple APIs, webhooks |
| REST API | Full-featured, API keys | Enterprise APIs       |
| GraphQL  | Flexible queries        | Complex data models   |

## Authentication Options

| Type      | Description                        |
| --------- | ---------------------------------- |
| None      | Public API                         |
| API Key   | Simple key-based auth              |
| JWT       | Token-based (Cognito/AAD/Firebase) |
| OAuth 2.0 | Third-party integration            |
| IAM       | AWS service-to-service             |

## Usage

1. Select cloud provider
2. Choose runtime and memory size
3. Configure API type and authentication
4. Enable database and storage options
5. Configure observability

## Outputs

- API Gateway endpoint URL
- Function ARN/name
- Database connection info
- Auth provider details (if enabled)
