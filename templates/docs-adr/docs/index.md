# Architecture Decision Records Template

This template creates a comprehensive documentation site for Architecture Decision Records (ADRs), providing teams with a structured way to capture, track, and share important architectural decisions.

---

## 1. Overview

### What are ADRs?

Architecture Decision Records (ADRs) are lightweight documents that capture important architectural decisions made by a team, including the context in which they were made and the consequences of those decisions. ADRs serve as a historical record that helps teams understand why certain architectural choices were made, preventing the repetition of past discussions and enabling faster onboarding of new team members.

### Why ADRs Matter

**Problems ADRs Solve:**

- Decisions discussed in meetings but never documented
- Knowledge buried in chat history, email threads, or people's heads
- Repeated discussions about the same topics
- Difficult for new team members to understand architectural context
- Lack of transparency in decision-making process

**Benefits of Using ADRs:**

- **Knowledge Preservation**: Capture institutional knowledge before it walks out the door
- **Historical Context**: Understand why decisions were made, not just what was decided
- **Reduced Rework**: Avoid revisiting settled debates
- **Onboarding Acceleration**: New team members can quickly understand architectural rationale
- **Accountability**: Transparent decision-making process
- **Learning**: Document both successes and failures for future reference

## 2. Features

This template provides a comprehensive ADR documentation system with:

### **Structured Format**

- Consistent MADR (Markdown Architecture Decision Records) template
- Standardized sections for context, decision, and consequences
- Support for multiple ADR formats (MADR, Nygard, or custom)

### **MkDocs Integration**

- Beautiful, searchable documentation site
- Professional styling with techdocs-core plugin
- Table of contents, permalinks, and admonition support
- Responsive design that works on all devices

### **Version History**

- Track decision evolution over time
- Never delete ADRs, only deprecate or supersede
- Clear audit trail of architectural changes

### **Searchable Documentation**

- Full-text search across all ADRs
- Quick navigation through MkDocs search functionality
- Category-based organization for easy filtering

### **Git-Based Workflow**

- ADRs live in version control alongside code
- Review process through pull requests
- Branch-based workflow familiar to development teams

## 3. Prerequisites

Before using this template, ensure you have:

### MkDocs Requirements

- **Python 3.7+** installed
- **MkDocs** and **techdocs-core** plugin
  ```bash
  pip install mkdocs mkdocs-techdocs-core
  ```

### Knowledge Requirements

- Understanding of architectural patterns and design decisions
- Familiarity with markdown documentation
- Basic git workflow knowledge
- Understanding of your team's decision-making process

### Tooling (Optional but Recommended)

- **ADR Tools**: For command-line ADR management
  ```bash
  npm install -g adr-tools
  # or
  brew install adr-tools
  ```
- **Pre-commit Hooks**: For ADR validation
- **CI/CD Pipeline**: For automated documentation builds

## 4. Configuration Options

When creating a new ADR repository using this template, the following parameters are available:

| Parameter         | Type    | Required | Default                                                                        | Description                                                       |
| ----------------- | ------- | -------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| `name`            | string  | Yes      | -                                                                              | Repository name (lowercase, alphanumeric with hyphens)            |
| `description`     | string  | No       | "Architecture Decision Records for tracking important architectural decisions" | Repository purpose                                                |
| `owner`           | string  | Yes      | -                                                                              | Team that owns this ADR repository (selected from catalog groups) |
| `adrFormat`       | enum    | No       | "madr"                                                                         | ADR template format: `madr`, `nygard`, or `custom`                |
| `includeExamples` | boolean | No       | true                                                                           | Include sample ADRs to help teams get started                     |
| `categories`      | array   | No       | `["architecture", "security", "infrastructure", "data"]`                       | ADR categories for organization                                   |
| `repoUrl`         | string  | Yes      | -                                                                              | GitHub repository location where ADRs will be published           |

### Configuration Examples

**Minimal Configuration:**

```yaml
name: payment-service-adrs
owner: group:payments-team
repoUrl: github.com?owner=myorg&repo=payment-service-adrs
```

**Full Configuration:**

```yaml
name: platform-architecture-adrs
owner: group:architecture-team
description: ADRs for platform-wide architectural decisions
adrFormat: madr
includeExamples: true
categories:
  - architecture
  - security
  - infrastructure
  - data
  - integration
  - performance
repoUrl: github.com?owner=myorg&repo=platform-architecture-adrs
```

## 5. ADR Template Deep Dive

The template uses the MADR (Markdown Architecture Decision Records) format, which provides a comprehensive structure for documenting decisions.

### Template Structure

```markdown
# ADR NNN: Title

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR XXX](XXX-title.md)

## Context

What is the issue that we're seeing that is motivating this decision or change?

Describe:

- The current situation
- The problem or opportunity
- Forces at play (technical, business, organizational)
- Constraints that limit options

## Decision

What is the change that we're proposing and/or doing?

Be specific and unambiguous. State the decision clearly so that someone reading this in the future understands exactly what was decided.

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- Benefit 1
- Benefit 2
- Benefit 3

### Negative

- Drawback 1
- Drawback 2
- Risk we accept

## Alternatives Considered

### Alternative 1: [Name]

Description of the alternative.

**Pros:**

- Advantage

**Cons:**

- Disadvantage
- Why not chosen

### Alternative 2: [Name]

Description of the alternative.

**Pros:**

- Advantage

**Cons:**

- Disadvantage
- Why not chosen

## References

- [Link to relevant documentation]()
- [Related ADR](NNN-title.md)
```

### Section-by-Section Explanation

#### **Title and Number (ADR NNN: Title)**

- **NNN**: Sequential number (001, 002, 003, etc.)
- **Title**: Short, descriptive title that captures the essence of the decision
- **Example**: "ADR 001: Use PostgreSQL as Primary Database"

#### **Status**

Current state of the decision. Must be one of:

- **Proposed**: Decision is being discussed but not yet finalized
- **Accepted**: Decision has been reviewed and approved
- **Deprecated**: Decision is no longer recommended but remains documented
- **Superseded by [ADR XXX]**: Decision has been replaced by a newer ADR

**Important**: Always update status when circumstances change.

#### **Context**

The most important section. Explain the "why" behind the decision:

- **Current Situation**: What exists today?
- **Problem/Opportunity**: What problem are we solving or opportunity addressing?
- **Forces**: What technical, business, or organizational pressures influence this?
- **Constraints**: What limitations restrict our options?
- **Timing**: Why are we making this decision now?

**Example**:

```markdown
## Context

Our monolithic application is experiencing performance issues during peak traffic.
Current response times exceed 2 seconds for 95th percentile, impacting user experience.
The business is planning a major marketing campaign that will increase traffic by 300%.
We need to architect a solution that can scale horizontally while maintaining reliability.
Team expertise is primarily in Java, and we have a 3-month timeline before the campaign launch.
```

#### **Decision**

Clear, unambiguous statement of what was decided:

- Be specific: "Use" instead of "Consider using"
- Include key parameters and constraints
- Mention any exceptions or conditions
- Reference standards or patterns being adopted

**Example**:

```markdown
## Decision

We will implement a microservices architecture using Spring Boot and Netflix OSS.
Key aspects:

1. Decompose the monolith into 5 services: User Service, Order Service, Payment Service, Inventory Service, and Notification Service
2. Use API Gateway pattern with Spring Cloud Gateway
3. Implement service discovery using Netflix Eureka
4. Use asynchronous communication via RabbitMQ for event-driven flows
5. Maintain existing PostgreSQL database per service initially, migrate to service-specific databases in Phase 2
```

#### **Consequences**

Split into positive and negative to provide balanced view:

**Positive:**

- What becomes easier, faster, or better?
- What pain points are eliminated?
- What new capabilities are enabled?

**Negative:**

- What becomes harder or more complex?
- What tradeoffs are we accepting?
- What risks are we taking on?
- What additional work is required?

**Example**:

```markdown
## Consequences

### Positive

- Independent scaling of services based on demand
- Teams can work on different services in parallel
- Technology diversity possible per service
- Fault isolation improves system reliability
- Deployment frequency can increase

### Negative

- Increased operational complexity with 5 services instead of 1
- Network latency between services may impact performance
- Data consistency challenges across services
- Requires investment in monitoring and observability
- Team needs to learn distributed systems patterns
- Initial development slower due to infrastructure setup
```

#### **Alternatives Considered**

Document at least 2-3 alternatives that were seriously considered:

For each alternative:

- **Description**: What the alternative entailed
- **Pros**: Advantages of this approach
- **Cons**: Disadvantages and why it wasn't chosen

This demonstrates thorough analysis and prevents revisiting the same options.

**Example**:

```markdown
## Alternatives Considered

### Alternative 1: Optimize Monolith

Keep the existing monolithic architecture but optimize database queries and add caching.

**Pros:**

- Lower risk and faster to implement
- No architectural changes required
- Team already familiar with codebase

**Cons:**

- Limited scalability ceiling
- Doesn't solve underlying architectural constraints
- Technical debt continues to accumulate
- May not support 300% traffic increase

### Alternative 2: Lift-and-Shift to Cloud

Move the monolith to a cloud provider with auto-scaling capabilities.

**Pros:**

- Quick path to improved scalability
- Minimal code changes required
- Managed infrastructure reduces ops burden

**Cons:**

- Expensive scaling (scaling up vs. scaling out)
- Doesn't address architectural limitations
- Vendor lock-in concerns
- Still a single point of failure
```

#### **References**

Link to supporting information:

- Technical documentation
- Meeting notes or discussion threads
- Related ADRs (especially superseded ones)
- External resources or research
- Performance benchmarks or proof-of-concept results

## 6. Creating New ADRs

Follow this step-by-step process to create ADRs:

### Step 1: Create a New Branch

```bash
# Create a feature branch for your ADR
git checkout -b adr/003-use-redis-caching
```

### Step 2: Copy the Template

```bash
# Navigate to the ADRs directory
cd docs/adrs/

# Copy the template (you'll need to know the next number)
cp ../templates/adr-template.md 003-use-redis-caching.md
```

### Step 3: Write the ADR

Edit the new file with your decision:

```bash
# Use your preferred editor
vim 003-use-redis-caching.md
# or
code 003-use-redis-caching.md
```

### Step 4: Update Navigation

Edit `mkdocs.yml` to include the new ADR:

```yaml
nav:
  - Home: index.md
  - ADR Process: process.md
  - ADRs:
      - Overview: adrs/index.md
      - '001 - Use ADRs': adrs/001-use-adrs.md
      - '002 - Example Decision': adrs/002-example-decision.md
      - '003 - Use Redis Caching': adrs/003-use-redis-caching.md # Add this line
  - Templates: templates.md
```

### Step 5: Test Locally

```bash
# Serve the documentation locally
mkdocs serve

# Open http://localhost:8000 to review your ADR
```

### Step 6: Commit and Create Pull Request

```bash
# Add the new ADR and updated nav
git add docs/adrs/003-use-redis-caching.md mkdocs.yml

# Commit with descriptive message
git commit -m "ADR 003: Add decision to use Redis for caching layer

- Configure Redis as distributed cache
- Set TTL of 1 hour for product catalog
- Use Redis Sentinel for high availability
- Document performance improvement targets"

# Push and create PR
git push origin adr/003-use-redis-caching
```

### Step 7: Review Process

- Team reviews the ADR in the pull request
- Discuss alternatives and consequences
- Request changes if needed
- Approve when consensus is reached
- Merge to update status to "Accepted"

## 7. ADR Lifecycle

ADRs go through distinct states from proposal to retirement:

### **Proposed**

- Initial draft of the ADR
- Under active discussion and review
- Not yet implemented
- **Action**: Create PR and request team review

### **Accepted**

- Reviewed and approved by stakeholders
- Ready for implementation
- Represents team consensus
- **Action**: Merge PR and begin implementation

### **Implemented**

- Decision has been put into practice
- Code changes reflect the ADR
- May be separate from "Accepted" or combined
- **Action**: Update status after implementation is complete

### **Deprecated**

- Decision is no longer recommended
- Remains documented for historical reference
- New projects should not follow this pattern
- **Action**: Update status with rationale for deprecation

### **Superseded**

- Decision has been replaced by a newer ADR
- Link to the replacement ADR
- Old ADR remains for historical context
- **Action**: Update status and document what changed

**Example Lifecycle:**

```
ADR 002: Use MongoDB for User Data
  ↓ (Proposed → Accepted after review)
ADR 002: Use MongoDB for User Data [Accepted]
  ↓ (After 2 years, requirements change)
ADR 005: Migrate User Data to PostgreSQL [Proposed]
  ↓ (New ADR accepted)
ADR 002: Use MongoDB for User Data [Deprecated - No new collections]
  ↓ (Migration complete)
ADR 002: Use MongoDB for User Data [Superseded by ADR 005]
```

## 8. Example ADRs

Here are complete, realistic ADR examples covering different decision types:

### **Example 1: Technology Choice**

```markdown
# ADR 003: Use Redis for Session Storage

## Status

Accepted

## Context

Our application currently stores user sessions in PostgreSQL. As we scale to multiple web servers behind a load balancer, we face several issues:

- Database becomes a bottleneck during peak traffic
- Session queries account for 30% of database load
- Session cleanup queries impact overall database performance
- Need for session stickiness limits load distribution effectiveness
- Planned move to containerized deployment where session stickiness is problematic

Performance metrics show average session read time of 15ms, which increases to 50ms under load.

## Decision

We will use Redis as our session storage mechanism with the following configuration:

1. **Redis Setup**: Deploy Redis Cluster with 3 master and 3 replica nodes
2. **Client Library**: Use `redis-py` with connection pooling
3. **Session Format**: Store sessions as JSON with user ID, expiry, and custom data
4. **TTL**: Set default session TTL to 24 hours with sliding expiration
5. **Key Format**: `session:{user_id}:{session_token}`
6. **Persistence**: Enable AOF (Append Only File) with fsync every second
7. **High Availability**: Configure Redis Sentinel for automatic failover
8. **Security**: Use Redis AUTH and TLS encryption in transit

Migration plan:

- Phase 1: Deploy Redis and dual-write sessions (both PostgreSQL and Redis)
- Phase 2: Read from Redis with PostgreSQL fallback
- Phase 3: Remove PostgreSQL session storage after 30 days

## Consequences

### Positive

- Reduced database load by an estimated 30%
- Sub-2ms session read times vs. current 15-50ms
- Eliminates need for session stickiness, improving load distribution
- Automatic session expiration handling
- Better support for horizontal scaling of web tier
- Improved user experience with faster session validation

### Negative

- New operational component to manage and monitor
- Additional infrastructure cost (approximately $200/month for managed Redis)
- Team needs to learn Redis operational aspects
- Potential cold start issue if Redis experiences high cache miss rate
- Complex failover scenarios to test
- Migration complexity with dual-write phase

## Alternatives Considered

### Alternative 1: Continue with PostgreSQL Sessions

Optimize current PostgreSQL approach with improved indexing and connection pooling.

**Pros:**

- No new infrastructure required
- Team familiar with PostgreSQL operations
- Simple, proven approach

**Cons:**

- Doesn't solve fundamental scalability issues
- Database remains a performance bottleneck
- Limits containerization strategy
- Session cleanup still impacts performance

### Alternative 2: JWT Tokens

Use stateless JWT tokens for sessions.

**Pros:**

- No server-side session storage needed
- Truly stateless and horizontally scalable
- Industry standard for modern applications

**Cons:**

- Token size impacts request/response overhead
- Token revocation complexity (need blacklist)
- Security concerns if tokens are compromised
- Can't easily modify session data
- Token refresh complexity

### Alternative 3: Memcached

Use Memcached instead of Redis.

**Pros:**

- Very fast, proven technology
- Simpler than Redis
- Lower memory footprint

**Cons:**

- No persistence (data loss on restart)
- No built-in replication/failover
- Limited data structure support
- Less flexible for future use cases

## References

- [Redis Persistence Documentation](https://redis.io/topics/persistence)
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [Load Testing Results - JMeter Report](https://load-tests.example.com/ sessions-perf)
- [ADR 001: Use ADRs for Architecture Decisions](001-use-adrs.md)
```

### **Example 2: Architectural Pattern**

```markdown
# ADR 004: Implement Event-Driven Architecture for Order Processing

## Status

Accepted

## Context

Our current order processing system uses a monolithic, synchronous architecture with the following workflow:

1. Customer places order → Order Service validates → Payment Service processes → Inventory Service reserves → Notification Service sends confirmation

This approach has several problems:

- **Tight Coupling**: All services must be available for order completion
- **Performance**: Total response time is sum of all service latencies
- **Reliability**: Failure in any service fails the entire order
- **Scalability**: Can't scale individual processing steps independently
- **Flexibility**: Hard to add new order processing steps

Current peak load is 100 orders/minute, but we're targeting 1000+ orders/minute for holiday season.
Current order completion rate is 94% (6% fail due to downstream service issues).

## Decision

We will transition to an event-driven architecture for order processing with the following design:

1. **Event Bus**: Deploy Apache Kafka as our event streaming platform
2. **Event Types**: Standardize on CloudEvents specification
3. **Processing Flow**:
   - OrderCreated → InventoryReserved → PaymentProcessed → OrderConfirmed
   - Each step publishes event when complete
   - Next step consumes event and continues processing
4. **Event Schema Registry**: Use Confluent Schema Registry for event versioning
5. **Error Handling**: Implement dead-letter queues for failed events
6. **Idempotency**: All event consumers must be idempotent
7. **Event Sourcing**: Store Order events as source of truth
8. **SAGA Pattern**: Implement distributed transactions using choreography

Migration Strategy:

- Step 1: Deploy Kafka and implement event publishing alongside current flow
- Step 2: New order processing uses events, old flow remains for existing
- Step 3: Migrate existing orders to event-driven flow
- Step 4: Decommission synchronous flow completely

## Consequences

### Positive

- **Loose Coupling**: Services only need to know about events, not each other
- **Improved Reliability**: Orders can complete even if some services temporarily unavailable
- **Better Performance**: Parallel processing possible, reduced response times
- **Enhanced Scalability**: Each processing step can scale independently
- **Flexibility**: New processing steps can be added by subscribing to events
- **Observability**: Event stream provides detailed audit trail
- **Target Metrics**: Project 99%+ order completion rate, support 2000+ orders/min

### Negative

- **Complexity**: Distributed systems are inherently more complex
- **Debugging**: Harder to trace request flow across services
- **Eventual Consistency**: System will be eventually consistent, not strongly consistent
- **New Infrastructure**: Kafka cluster requires setup, monitoring, and maintenance
- **Learning Curve**: Team needs to learn event-driven patterns and Kafka
- **Data Consistency**: Must handle duplicate events and out-of-order delivery
- **Testing**: Integration testing more complex with asynchronous flows

## Alternatives Considered

### Alternative 1: Orchestration Pattern (Synchronous)

Keep current approach but implement a central orchestrator service.

**Pros:**

- Simpler to understand and debug
- Centralized control and monitoring
- Strong consistency

**Cons:**

- Orchestrator becomes a single point of failure
- Still has tight coupling issues
- Limited scalability
- Orchestrator becomes a bottleneck

### Alternative 2: Choreography without Event Bus

Have services communicate directly via HTTP webhooks.

**Pros:**

- Simpler initial setup (no Kafka)
- Familiar HTTP-based communication
- Easier for simple workflows

**Cons:**

- Point-to-point coupling remains
- No event persistence or replay
- Difficult to add new subscribers
- No central event monitoring
- Can't handle high throughput

### Alternative 3: Message Queue (RabbitMQ)

Use traditional message queuing instead of event streaming.

**Pros:**

- Mature, stable technology
- Simpler than Kafka for basic use cases
- Good routing capabilities

**Cons:**

- Messages not persisted long-term by default
- Lower throughput than Kafka
- Harder to replay events for new consumers
- Less suitable for event sourcing pattern

## References

- [Building Event-Driven Microservices - O'Reilly](https://www.oreilly.com/library/view/building-event-driven-microservices/9781492057888/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [CloudEvents Specification](https://cloudevents.io/)
- [Current Order Processing Metrics Dashboard](https://grafana.example.com/orders)
- [ADR 003: Use Redis for Session Storage](003-use-redis-caching.md)
```

### **Example 3: Process Decision**

```markdown
# ADR 005: Require Load Testing for All Performance-Critical Changes

## Status

Accepted

## Context

We've experienced several production incidents related to performance:

1. **Memory Leak**: Slow growth over 2 weeks caused OOM crashes
2. **Database Connection Exhaustion**: Pool misconfiguration under load
3. **Response Time Degradation**: New feature added 400ms to critical path
4. **Cache Stampede**: Cold cache after deployment caused database overload

These issues share common patterns:

- Not caught in development or staging
- Impacted users before detection
- Required emergency hotfixes
- Could have been prevented with load testing

Current testing only includes unit and integration tests. No performance validation before production.

## Decision

We will implement a mandatory load testing requirement for all performance-critical changes:

1. **When Required**: Load testing is mandatory for changes that:

   - Affect request/response paths
   - Modify database queries or schema
   - Change caching behavior
   - Update connection pool configurations
   - Add external API calls
   - Modify authentication/authorization flows

2. **Performance Budget**: Establish and enforce budgets:

   - P95 response time: < 200ms
   - Error rate: < 0.1%
   - Memory growth: < 10% over 1 hour sustained load
   - CPU utilization: < 80% at peak load
   - Database query time: < 50ms average

3. **Load Scenarios**: Test must include:

   - Baseline: Current production traffic patterns
   - Peak: 2x expected peak load
   - Stress: 5x normal load (to identify breaking points)
   - Spike: Sudden 10x traffic increase
   - Endurance: 2-hour sustained load test

4. **Tools and Environment**:

   - Use k6 for load testing (open source, developer-friendly)
   - Test environment must mirror production (same instance types, database, etc.)
   - Tests run as part of CI/CD pipeline
   - Results stored in Git with the ADR

5. **Review Process**:

   - Load test results must be included in PR
   - Architecture team reviews if budgets are exceeded
   - Approval required before merge to main
   - Document any budget exceptions with justification

6. **Monitoring**:
   - Compare test metrics with actual production metrics
   - Alert if production diverges significantly from test results
   - Quarterly review of performance budgets

Implementation Timeline:

- Week 1-2: Deploy k6 setup and baseline tests
- Week 3-4: Create initial test suite for critical paths
- Week 5: Enable mandatory load testing gate
- Ongoing: Add tests for new features and optimizations

## Consequences

### Positive

- **Early Detection**: Performance issues caught before production
- **Confidence**: Quantified performance metrics for releases
- **Documentation**: Historical record of system performance characteristics
- **Regression Prevention**: Automated performance regression detection
- **Education**: Team builds expertise in performance testing
- **Better Design**: Forces consideration of performance during design phase

### Negative

- **Time Investment**: Adds 2-4 hours per performance-critical PR
- **Infrastructure Cost**: Additional test environment resources (~$500/month)
- **Learning Curve**: Team needs to learn k6 scripting
- **Maintenance**: Test scripts require ongoing updates
- **False Sense of Security**: Tests may not catch all production issues
- **May Slow Development**: Could be perceived as bureaucratic overhead

## Alternatives Considered

### Alternative 1: Continue Without Mandatory Load Testing

Rely on existing unit/integration tests and production monitoring.

**Pros:**

- No additional development overhead
- Team can move faster
- Existing process is familiar

**Cons:**

- Doesn't solve the performance incident problem
- Reactive rather than proactive
- Risk of continued production issues
- Harder to diagnose issues under pressure

### Alternative 2: Performance Testing Only for Major Releases

Require load testing only for significant releases, not every PR.

**Pros:**

- Less overhead for small changes
- Focuses testing effort on high-impact areas
- More manageable for small teams

**Cons:**

- Performance issues can still slip in between major releases
- Harder to attribute performance changes to specific code
- May not catch gradual performance degradation
- Encourages bundling changes (bad for debugging)

### Alternative 3: Use Commercial Load Testing Tool

Purchase enterprise load testing solution like LoadRunner or BlazeMeter.

**Pros:**

- Advanced features and reporting
- Professional support available
- Enterprise-grade capabilities

**Cons:**

- Expensive (often $10,000+ per year)
- Vendor lock-in
- Overkill for our current needs
- Less developer-friendly than open-source alternatives

### Alternative 4: Production Traffic Replay

Mirror production traffic to staging for realistic load testing.

**Pros:**

- Most realistic test scenarios
- No manual test script creation
- Catches real-world usage patterns

**Cons:**

- Complex to implement safely
- Risk of affecting production
- May include sensitive production data
- Hard to test scenarios that don't occur in production
- Significant infrastructure complexity

## References

- [k6 Load Testing Tool](https://k6.io/)
- [Performance Budgets](https://web.dev/performance-budgets-101/)
- [Previous Incident Post-Mortems](https://wiki.example.com/incidents)
- [Current Performance Metrics](https://grafana.example.com/performance)
- [ADR 004: Implement Event-Driven Architecture](004-event-driven-architecture.md)
```

## 9. MkDocs Configuration

The template includes a pre-configured MkDocs setup optimized for ADR documentation.

### **mkdocs.yml Structure**

```yaml
site_name: ${{ values.name }}
site_description: ${{ values.description }}

nav:
  - Home: index.md
  - ADR Process: process.md
  - ADRs:
      - Overview: adrs/index.md
      - '001 - Use ADRs': adrs/001-use-adrs.md
      - '002 - Example Decision': adrs/002-example-decision.md
  - Templates: templates.md

plugins:
  - techdocs-core

markdown_extensions:
  - admonition
  - toc:
      permalink: true
  - tables
```

### **Customization Options**

**Add Custom CSS:**

```yaml
extra_css:
  - stylesheets/extra.css
```

**Add Plugins:**

```yaml
plugins:
  - techdocs-core
  - search
  - git-revision-date-localized
  - minify

extra:
  generator: false # Hide "Built with MkDocs" text
```

**Configure Site Appearance:**

```yaml
theme:
  name: material
  palette:
    - scheme: default
      primary: blue
      accent: blue
      toggle:
        icon: material/lightbulb-outline
        name: Switch to dark mode
    - scheme: slate
      primary: blue
      accent: blue
      toggle:
        icon: material/lightbulb
        name: Switch to light mode
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - toc.integrate
```

### **Local Development**

```bash
# Install dependencies
pip install mkdocs mkdocs-techdocs-core mkdocs-material

# Serve locally with auto-reload
mkdocs serve

# Build static site
mkdocs build

# Deploy to various platforms
mkdocs gh-deploy  # GitHub Pages
mkdocs s3-deploy  # AWS S3 (with plugin)
```

## 10. Deployment

### **GitHub Pages (Recommended)**

The easiest deployment method for ADR repositories:

1. **Enable GitHub Pages:**

   - Repository Settings → Pages
   - Source: "Deploy from a branch"
   - Branch: `gh-pages` (will be created by mkdocs)

2. **Configure GitHub Actions:**
   Create `.github/workflows/deploy-docs.yml`:

```yaml
name: Deploy ADR Documentation

on:
  push:
    branches:
      - main
    paths:
      - 'docs/**'
      - 'mkdocs.yml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install dependencies
        run: |
          pip install mkdocs mkdocs-techdocs-core

      - name: Build and deploy
        run: |
          mkdocs gh-deploy --force
```

3. **Access Your ADRs:**
   - Published at: `https://<org>.github.io/<repo>/`
   - Example: `https://mycompany.github.io/platform-adrs/`

### **Internal Server/Nginx**

For internal deployments:

```bash
# Build static site
mkdocs build

# Copy to web server
scp -r site/ user@internal-server:/var/www/html/adrs/

# Configure Nginx
server {
    listen 80;
    server_name adrs.internal.example.com;
    root /var/www/html/adrs;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### **Docker Deployment**

Deploy with Docker for containerized environments:

```dockerfile
FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN mkdocs build

FROM nginx:alpine
COPY --from=builder /app/site /usr/share/nginx/html
EXPOSE 80
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  adrs:
    build: .
    ports:
      - '8080:80'
    restart: unless-stopped
```

### **Netlify/Vercel**

For modern static hosting:

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=site
```

## 11. Best Practices

### **When to Write ADRs**

**Definitely Write ADRs For:**

- Technology choices (databases, frameworks, languages)
- Architectural patterns (microservices, monolith, event-driven)
- Infrastructure decisions (cloud provider, deployment strategy)
- Integration approaches (API design, messaging patterns)
- Security decisions (authentication, authorization, encryption)
- Performance tradeoffs (caching strategies, scaling decisions)
- Process changes (CI/CD, testing approaches, team structure)

**Skip ADRs For:**

- Routine coding decisions (variable names, function structure)
- Minor library updates (patch/security updates)
- Bug fixes (unless they reveal architectural issues)
- Personal preference (code formatting, IDE choices)

**Rule of Thumb**: If the decision affects how multiple developers work or impacts system architecture, write an ADR.

### **Writing Style Guidelines**

**Be Specific:**

- ❌ "We should use a fast database"
- ✅ "We will use PostgreSQL 14 with connection pooling via PgBouncer"

**Include Dates:**

```markdown
## Status

Accepted (2023-10-15)
```

**Use Clear Language:**

- Present tense for context: "Our system currently..."
- Future tense for decision: "We will implement..."
- Be unambiguous: Avoid "might", "could", "should"

**Keep it Current:**

- Review ADRs quarterly
- Update consequences as they become apparent
- Add "Lessons Learned" section after implementation

**Make it Discoverable:**

- Link related ADRs
- Cross-reference code repositories
- Mention related documentation

### **Review and Maintenance**

**Review Schedule:**

- **Monthly**: Quick scan for ADRs that need status updates
- **Quarterly**: Deep review of all accepted ADRs for relevance
- **Annually**: Audit of deprecated/superseded ADRs

**Update Triggers:**

- Technology becomes end-of-life
- Performance characteristics change
- Team learns new information
- Decision is superseded by new approach
- Consequences prove different than expected

**Archive Policy:**

- Never delete ADRs
- Keep deprecated ADRs for historical context
- Update status rather than removing content
- Link deprecated ADRs to their replacements

## 12. Integration

### **Linking ADRs to Code**

**Code Comments:**

```python
# Implementation of ADR 003: Use Redis for Session Storage
# See: docs/adrs/003-use-redis-caching.md
def get_session(user_id, token):
    session = redis_client.get(f"session:{user_id}:{token}")
    return json.loads(session) if session else None
```

**Git Commit Messages:**

```
feat: implement Redis session storage

Implements ADR 003 for distributed session management.
- Add Redis client configuration
- Implement session store/retrieve methods
- Add Redis Sentinel for HA

See docs/adrs/003-use-redis-caching.md
```

**Pull Request Templates:**

```markdown
## Description

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## ADR Reference

- [ ] This change implements ADR: \_\_\_
- [ ] This change requires new ADR: \_\_\_
- [ ] N/A

## Testing

- [ ] Unit tests added
- [ ] Integration tests added
- [ ] Load tests added (if performance-critical)
```

### **Jira Integration**

**Link ADRs to Jira Issues:**

```markdown
## References

- [Jira - OPS-1234: Performance issues with session management](https://jira.example.com/browse/OPS-1234)
- [Jira - ARCH-567: Investigate Redis for caching](https://jira.example.com/browse/ARCH-567)
```

**Automate with Jira Webhook:**

```python
# When ADR status changes to "Accepted", update related Jira tickets
# Example webhook handler

def update_jira_adr_status(adr_number, new_status):
    jira_ticket = find_related_jira_ticket(adr_number)
    if jira_ticket:
        jira.add_comment(
            jira_ticket,
            f"ADR {adr_number} status updated to: {new_status}"
        )
        if new_status == "Accepted":
            jira.transition_issue(jira_ticket, "Approved")
```

### **Confluence Integration**

**Embed ADRs in Confluence:**

```markdown
# Use Confluence's markdown macro or iframe

## Architecture Decision: Redis for Session Storage

View our ADR documentation: [ADR 003 - Use Redis for Session Storage](https://adrs.example.com/adrs/003-use-redis-caching/)

<iframe src="https://adrs.example.com/adrs/003-use-redis-caching/" 
        width="100%" height="800px"></iframe>
```

**Sync ADRs to Confluence:**

```bash
#!/bin/bash
# Script to sync ADRs to Confluence

for adr in docs/adrs/*.md; do
    if [ "$adr" != "docs/adrs/index.md" ]; then
        title=$(grep "^# ADR" "$adr" | sed 's/# ADR/Architecture Decision/')
        confluence-publish \
            --space ADRS \
            --title "$title" \
            --file "$adr" \
            --markdown
    fi
done
```

### **Backstage Integration**

This template includes Backstage TechDocs integration out of the box:

**catalog-info.yaml:**

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: platform-adrs
  description: Architecture Decision Records for platform
  annotations:
    backstage.io/techdocs-ref: dir:.
    github.com/project-slug: myorg/platform-adrs
  tags:
    - documentation
    - adr
    - architecture
spec:
  type: documentation
  lifecycle: production
  owner: group:architecture-team
```

**Linking ADRs to Components:**
In your service's catalog-info.yaml:

```yaml
metadata:
  annotations:
    adr.example.com/related: |
      - adr-003-use-redis-caching.md
      - adr-004-event-driven-architecture.md
```

## 13. Related Templates

This ADR template works well with other documentation templates:

### **[docs-project](https://github.com/myorg/templates/docs-project)**

For comprehensive project documentation that may reference ADRs:

- Project overview and architecture
- API documentation
- Link to relevant ADRs explaining architectural choices
- Addition to main documentation navigation

**Integration Pattern:**

```
project-docs/
├── docs/
│   ├── index.md
│   ├── architecture/
│   │   ├── overview.md
│   │   └── decisions.md  # Links to ADR repository
│   └── adr/  # Submodule or reference to ADR repo
│       └── index.md
```

### **[docs-runbook](https://github.com/myorg/templates/docs-runbook)**

For operational procedures that may implement ADR decisions:

- Operational impact of architectural decisions
- Troubleshooting procedures
- Incident response related to ADR implementations

**Example Runbook Entry:**

```markdown
# Runbook: Redis Session Cache Outage

## Related ADRs

- ADR 003: Use Redis for Session Storage
- ADR 005: Require Load Testing

## Impact

Users cannot log in or maintain sessions during Redis outage.

## Procedure

1. Check Redis Cluster status
2. Failover to backup Redis if primary is down
3. If complete Redis failure, activate emergency session mode (see ADR 003 for fallback)
4. Monitor error rates and user impact
```

### **[service-template](https://github.com/myorg/templates/service-template)**

For new microservices that should be aware of ADRs:

- Include ADR repository link in service onboarding
- Generate service-specific ADRs from decisions made during creation
- Link to platform-wide ADRs that affect all services

**Service Creation Checklist:**

```markdown
- [ ] Service created from template
- [ ] Review platform ADRs:
  - ADR 004: Event-Driven Architecture
  - ADR 007: API Gateway Pattern
  - ADR 012: Observability Standards
- [ ] Create service-specific ADRs if needed
- [ ] Link ADRs in service documentation
```

### **Template Ecosystem Integration**

**Using Multiple Templates Together:**

```
1. Create ADR repository (docs-adr template)
   └─> Documents architectural decisions

2. Create project documentation (docs-project)
   └─> References ADRs in architecture section

3. Create runbook (docs-runbook)
   └─> Operationalizes ADR decisions

4. Create services (service-template)
   └─> Implements ADR-defined patterns
```

**Benefits of Integrated Templates:**

- **Consistency**: All projects follow same documentation standards
- **Traceability**: Link decisions → implementation → operations
- **Knowledge Sharing**: Common template language and structure
- **Efficiency**: Teams can quickly spin up standardized projects
- **Quality**: Built-in best practices and review processes

---

## Support and Resources

### Getting Help

- **Architecture Team**: architecture@example.com
- **Slack Channel**: #architecture-decisions
- **Office Hours**: Tuesdays 2-3 PM (Zoom link in team calendar)

### Additional Resources

- [MADR GitHub Repository](https://github.com/adr/madr)
- [Documenting Architecture Decisions by Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [Backstage TechDocs Documentation](https://backstage.io/docs/features/techdocs/techdocs-overview)

### Contributing

We welcome improvements to this template! Please:

1. Create an issue describing the proposed change
2. Submit a pull request with your improvements
3. Participate in review discussions

---

_Last Updated: 2025-12-23_  
_Template Version: 2.0.0_
