# High-level design

## Purpose

${{ values.description }}

This document says what ${{ values.systemName }} is, who uses it, what it is
made of and the decisions that shaped it. It is for the people who approve
the design and for every team that builds on it.

## Scope

| In scope | Out of scope |
| --- | --- |
| The capabilities listed under [Requirements](#requirements) | Anything owned by a surrounding system in the [context](#context) |
| Production and the environments leading to it | Tooling used only on a developer's machine |

## Requirements

### What it must do

| ID | Requirement | Priority |
| --- | --- | --- |
| F-1 | A customer can create a record and see its state | Must |
| F-2 | A customer is told when a record changes state | Must |
| F-3 | Operations staff can find a record and correct it, with a reason | Must |
| F-4 | Records are exchanged with the partner once a day | Should |

### How well it must do it

| ID | Quality | Measure | Target |
| --- | --- | --- | --- |
| Q-1 | Availability | Successful requests over a month | 99.9% |
| Q-2 | Latency | 95th percentile of API responses | Under 300 ms |
| Q-3 | Durability | Recovery point after loss of a zone | Zero |
| Q-4 | Recovery | Time to restore service in the recovery region | Under 4 hours |
| Q-5 | Security | Data encrypted in transit and at rest | Always |
| Q-6 | Accessibility | Web pages | WCAG 2.2 AA |

## Context

Who uses ${{ values.systemName }}, and the systems it depends on.

![System context](diagrams/context.d2)

| Element | Kind | Responsibility |
| --- | --- | --- |
| Customer | Person | Creates records and follows their progress |
| Operations staff | Person | Supports customers and resolves exceptions |
| Identity provider | External system | Signs people in with OpenID Connect |
| Notification service | External system | Sends email and text messages |
| Partner API | External system | Receives and returns records |

## Containers

The parts that are built and deployed separately.

![Containers](diagrams/containers.d2)

| Container | Technology | Responsibility |
| --- | --- | --- |
| Web application | Single-page application | What a customer sees. Holds no secrets |
| API | Stateless service | Owns the business rules. The only writer to the database |
| Worker | Queue consumer | Work that must not hold up a request: messages, partner exchange |
| Database | Relational | The system of record |
| Event queue | Durable queue | Decouples the API from slow or unreliable work |
| Cache | In-memory store | Sessions and read-through cache. Safe to lose |

## Deployment

Where the containers run in production.

![Deployment](diagrams/deployment.d2)

| Concern | Approach |
| --- | --- |
| Zones | API and worker run in three zones. The database has a standby in a second zone |
| Scaling | API on request rate, worker on queue depth |
| Recovery | The database replicates to the recovery region. Infrastructure is code, so the region is rebuilt, not kept warm |
| Environments | Development, staging and production, each in its own account, built from the same code |

## Cross-cutting concerns

| Concern | Approach |
| --- | --- |
| Authentication | OpenID Connect at the identity provider. The API accepts only its tokens |
| Authorisation | Roles carried in the token, enforced in the API for every request |
| Secrets | Held in the platform's secret store, read at start-up, never in code or images |
| Observability | Structured logs, metrics and traces through OpenTelemetry, joined by a trace id |
| Data protection | Personal data is listed in the low-level design with its retention period |
| Change | Trunk-based. Every change is built, tested and deployed by the pipeline |

## Decisions

The decisions that shaped this design. Each has its own record once it is
more than a line.

| ID | Decision | Why | Status |
| --- | --- | --- | --- |
| D-1 | One relational database, written only by the API | One place enforces the rules. Reporting reads a replica | Agreed |
| D-2 | Events through an outbox table | A change and its event are committed together or not at all | Agreed |
| D-3 | Rebuild, not standby, in the recovery region | Meets Q-4 at a fraction of the running cost | Proposed |

## Risks and assumptions

| ID | Risk or assumption | Effect | Response | Owner |
| --- | --- | --- | --- | --- |
| R-1 | The partner API has no test environment | Integration faults found late | Contract tests against recorded responses. Agree a sandbox | |
| R-2 | Peak volume is an estimate | Under-provisioned at launch | Load test at three times the estimate before go-live | |
| A-1 | The identity provider is available at 99.95% | Sign-in fails when it is down | Sessions outlive a short outage | |

## Approval

| Role | Name | Date |
| --- | --- | --- |
| Design authority | | |
| Security | | |
| Service owner | | |

## Change history

| Version | Date | Change | Author |
| --- | --- | --- | --- |
| 0.1 | | First draft | |
