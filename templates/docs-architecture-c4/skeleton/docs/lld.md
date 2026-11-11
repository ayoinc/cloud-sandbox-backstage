# Low-level design

How the parts named in the [high-level design](hld.md) are built. It is for
the people who write, test and operate ${{ values.systemName }}.

## Components

What the API is made of.

![API components](diagrams/components.d2)

| Component | Responsibility | Depends on |
| --- | --- | --- |
| HTTP layer | Routing, request validation, authentication, rate limits | Application services |
| Application services | One per use case. Opens and commits the transaction | Domain model, repositories, service clients |
| Domain model | Business rules. No input or output | Nothing |
| Repositories | Loads and stores aggregates | Database |
| Outbox publisher | Publishes events recorded with the change | Database, event queue |
| Service clients | Calls to the identity provider and cache, with timeouts and retries | Identity provider, cache |

## Behaviour

### Creating a record

![Creating a record](diagrams/sequence-request.d2)

| Step | Rule |
| --- | --- |
| Validate | Reject with 400 and a problem document naming each invalid field |
| Authorise | The caller must own the account. Otherwise 403 |
| Idempotency | A repeated key returns the first response and changes nothing |
| Commit | The record and its outbox row are written in one transaction |
| Publish | At least once. Consumers ignore an event they have already handled |

### Record states

| From | Event | To | Rule |
| --- | --- | --- | --- |
| | Created | Pending | |
| Pending | Accepted | Active | Checks passed |
| Pending | Rejected | Closed | A reason is recorded |
| Active | Cancelled | Closed | Only by the owner or operations staff |

## Data

![Data model](diagrams/data-model.d2)

| Table | Holds | Personal data | Kept for |
| --- | --- | --- | --- |
| `account` | Who a record belongs to | Email address | Life of the account plus 30 days |
| `record` | The record and its current state | None | 7 years |
| `record_event` | Every change to a record | None | 7 years |
| `outbox` | Events waiting to be published | None | 7 days after publishing |

Money is held as an integer of minor units with its currency. Times are UTC.
Every table has a primary key that is never reused.

## Interfaces

### API

The OpenAPI description in the service repository is the contract. The
resources are:

| Method and path | Purpose | Success | Errors |
| --- | --- | --- | --- |
| `POST /records` | Create a record | 201 | 400, 401, 403, 409 |
| `GET /records/{id}` | Read a record | 200 | 401, 403, 404 |
| `GET /records` | List the caller's records, paged by cursor | 200 | 400, 401 |
| `POST /records/{id}/cancel` | Cancel a record | 200 | 401, 403, 404, 409 |

Errors are problem documents (RFC 9457). Every response carries the trace id.

### Events

| Event | Published when | Consumers |
| --- | --- | --- |
| `RecordCreated` | A record is committed | Worker (notification) |
| `RecordStateChanged` | A record changes state | Worker (notification, partner exchange) |

Events carry an id, a type, a version, the time and the record id. A consumer
reads the record for anything else, so an event never goes stale.

## Failure handling

| Failure | Detection | Behaviour |
| --- | --- | --- |
| Database unavailable | Health check, error rate | API answers 503. Nothing is accepted that cannot be stored |
| Queue unavailable | Outbox backlog | Requests still succeed. Events are published when it returns |
| Notification service slow | Worker latency | Retried with backoff, then parked in a dead-letter queue and alerted |
| Partner API rejects a record | Response code | Recorded against the record. Operations staff are told |

## Security

| Control | Where |
| --- | --- |
| TLS 1.2 or later on every connection | Load balancer, service mesh, database |
| Tokens validated for signature, issuer, audience and expiry | HTTP layer |
| Least privilege database roles: the API reads and writes, reporting only reads | Database |
| Input validated against the schema. Output encoded | HTTP layer, web application |
| Dependencies scanned on every build. Images signed | Pipeline |
| Audit trail of every change by operations staff | `record_event` |

## Operations

| Signal | Alert when | Response |
| --- | --- | --- |
| Availability (Q-1) | Error budget burning at 14 times the allowed rate for 5 minutes | Page the on-call engineer |
| Latency (Q-2) | 95th percentile over target for 15 minutes | Page the on-call engineer |
| Outbox backlog | Oldest unpublished event older than 5 minutes | Notify the team channel |
| Dead-letter queue | Not empty | Notify the team channel |

Runbooks for each alert live with the service. A deployment is rolled back by
deploying the previous version: database changes are backward compatible for
one release.

## Testing

| Level | Covers | Runs |
| --- | --- | --- |
| Unit | Domain model and application services | Every commit |
| Contract | The API against its OpenAPI description. Events against their schemas | Every commit |
| Integration | Repositories and the outbox against a real database | Every commit |
| End to end | The journeys under [Behaviour](#behaviour) through the web application | Before each release |
| Load | Three times the expected peak (R-2) | Before go-live and each quarter |
