# ${{ values.name }}

${{ values.description }}

## Overview

D2 is a modern, declarative diagramming language that makes it easy to create and maintain software architecture diagrams. Unlike traditional diagramming tools, D2 uses a simple text-based syntax that can be version-controlled, reviewed, and integrated into your documentation workflow.

This guide provides comprehensive documentation for using D2 diagrams within your Backstage TechDocs. It covers everything from basic syntax to advanced features, helping you create clear and maintainable architectural visualizations.

### Key Benefits

- **Version Control**: Diagrams are text files that can be tracked in Git
- **Code Review**: Changes to diagrams can be reviewed like code
- **Automation**: Diagrams can be generated as part of CI/CD pipelines
- **Consistency**: Theming ensures diagrams match your organization's style
- **Integration**: Native support in TechDocs via the mkdocs-d2 plugin

---

## Configuration Summary

This template was created with the following configuration:

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Name** | `${{ values.name }}` | The name of this documentation component |
| **Description** | `${{ values.description }}` | Brief description of the documentation |
| **Owner** | `${{ values.owner }}` | Team or individual responsible for this documentation |
| **Type** | `documentation` | Backstage component type |
| **Lifecycle** | `production` | Current lifecycle stage |

### Template Features

| Feature | Status | Notes |
|---------|--------|-------|
| D2 Plugin | Enabled | Theme 4 (dark neutral) configured |
| TechDocs Core | Enabled | Standard Backstage documentation |
| Architecture Diagrams | Included | See [Architecture](architecture.md) |
| Example Patterns | Included | See [Examples](examples.md) |

---

## D2 Syntax Basics

D2 uses a simple, intuitive syntax for defining diagrams. The basic building blocks are shapes and connections.

### Defining Shapes

Shapes are the fundamental elements of any diagram. Simply write a name to create a shape:

```d2
# Basic shape definition
server
database
cache

# Shapes with labels (displayed text differs from ID)
api_server: API Server
user_db: User Database
redis_cache: Redis Cache
```

### Creating Connections

Connections define relationships between shapes. D2 supports several arrow types:

```d2
# Directional arrow (most common)
client -> server: HTTP Request

# Reverse direction
server <- client: Response

# Bidirectional arrow
service_a <-> service_b: Sync

# No arrow (simple line)
node_a -- node_b: Link

# Multiple connections from same source
api -> database
api -> cache
api -> queue
```

### Adding Labels

Labels provide context to shapes and connections:

```d2
# Shape with label
web_server: Nginx Web Server

# Connection with label
web_server -> app_server: Proxy Pass

# Multi-line labels
service: |md
  ## Microservice
  - Handles requests
  - Processes data
|
```

### Comments

Use hash symbols for comments:

```d2
# This is a comment
server  # Inline comment

# Comments are ignored in output
# Use them to document your diagrams
```

---

## Shape Types

D2 provides various shape types to represent different architectural components.

### Available Shapes

```d2
# Standard shapes
rectangle: Rectangle {
  shape: rectangle
}

square: Square {
  shape: square
}

oval: Oval {
  shape: oval
}

circle: Circle {
  shape: circle
}

diamond: Diamond {
  shape: diamond
}

# Infrastructure shapes
cylinder: Database {
  shape: cylinder
}

queue: Message Queue {
  shape: queue
}

cloud: Cloud Service {
  shape: cloud
}

# Documentation shapes
page: Document {
  shape: page
}

package: Package {
  shape: package
}

# Special shapes
person: User {
  shape: person
}

hexagon: Service {
  shape: hexagon
}

parallelogram: Process {
  shape: parallelogram
}
```

### Shape Reference Table

| Shape | Use Case | Example |
|-------|----------|---------|
| `rectangle` | Generic component, default | Services, modules |
| `square` | Equal-sized component | Grid layouts |
| `oval` | Start/end points | Flow diagrams |
| `circle` | States, nodes | State machines |
| `diamond` | Decisions | Flow charts |
| `cylinder` | Data storage | Databases, caches |
| `queue` | Message systems | Kafka, RabbitMQ |
| `cloud` | External services | AWS, GCP, Azure |
| `page` | Documents | Configs, specs |
| `package` | Grouped components | Libraries, modules |
| `person` | Users, actors | User flows |
| `hexagon` | Services | Microservices |

---

## Connection Types

D2 supports various connection styles for different relationship types.

### Arrow Styles

```d2
# Standard arrows
a -> b: Forward
b <- a: Backward
a <-> b: Bidirectional

# No arrow
a -- b: Line only

# Multiple arrow heads
a <-> b: Two-way communication
```

### Connection Styling

```d2
# Dashed connection
service -> external: API Call {
  style.stroke-dash: 5
}

# Animated connection (for web)
request -> response: Stream {
  style.animated: true
}

# Colored connection
success_path: {
  a -> b: Success {
    style.stroke: green
  }
}

# Thick connection
primary_flow: {
  x -> y: Main Flow {
    style.stroke-width: 3
  }
}
```

### Connection Labels

```d2
# Simple label
api -> db: SQL Query

# Label with markdown
api -> cache: |md
  **Cache Lookup**
  - Check TTL
  - Return if valid
|

# Multiple labels (creates multiple connections)
client -> server: GET
client -> server: POST
client -> server: PUT
```

---

## Layouts and Positioning

Control the layout and direction of your diagrams.

### Direction

```d2
# Top to bottom (default)
direction: down

a -> b -> c

# Left to right
direction: right

x -> y -> z

# Other options: up, left
```

### Near Positioning

```d2
# Position elements near specific locations
title: System Overview {
  shape: text
  near: top-center
}

legend: Legend {
  near: bottom-right
}
```

### Grid Layout

```d2
grid-rows: 2
grid-columns: 3

a
b
c
d
e
f
```

### Positioning with Constraints

```d2
# Force specific ordering
a
b
c

a -> b
b -> c

# Use containers to group related elements
group1: {
  a
  b
}

group2: {
  c
  d
}

group1 -> group2
```

---

## Styling

D2 provides extensive styling options for shapes and connections.

### Basic Styling

```d2
styled_box: Styled Component {
  style: {
    fill: "#E3F2FD"
    stroke: "#1976D2"
    stroke-width: 2
    border-radius: 8
    font-color: "#333333"
    bold: true
  }
}
```

### Color Palette Examples

```d2
# Primary colors
primary: Primary {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

# Success/positive
success: Success {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

# Warning/caution
warning: Warning {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

# Error/critical
error: Error {
  style.fill: "#FFEBEE"
  style.stroke: "#D32F2F"
}

# Neutral/info
neutral: Neutral {
  style.fill: "#F5F5F5"
  style.stroke: "#757575"
}
```

### Font Styling

```d2
text_example: Styled Text {
  style: {
    font-size: 16
    font-color: "#333333"
    bold: true
    italic: false
    underline: false
  }
}
```

### Shadow and Effects

```d2
elevated: Elevated Card {
  style: {
    fill: white
    stroke: "#E0E0E0"
    shadow: true
    border-radius: 12
  }
}
```

### Global Styling with Classes

```d2
classes: {
  service: {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }
  database: {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }
}

user_service.class: service
order_service.class: service
users_db.class: database
orders_db.class: database

user_service -> users_db
order_service -> orders_db
```

---

## Themes

D2 includes built-in themes for consistent styling.

### Available Themes

| Theme ID | Name | Description |
|----------|------|-------------|
| 0 | Default | Light theme with blue accents |
| 1 | Neutral Gray | Grayscale theme |
| 2 | Flagship Terrastruct | Official Terrastruct theme |
| 3 | Cool Classics | Cool-toned palette |
| 4 | Mixed Berry Blue | Dark blue theme |
| 5 | Grape Soda | Purple theme |
| 6 | Aubergine | Dark purple theme |
| 7 | Colorblind Clear | Accessibility-focused |
| 8 | Vanilla Nitro Cold Brew | Warm dark theme |

### Setting Theme in mkdocs.yml

```yaml
plugins:
  - techdocs-core
  - d2:
      theme: 4  # Mixed Berry Blue
```

### Theme Configuration for TechDocs

The D2 plugin theme is configured in your `mkdocs.yml`. This template uses theme `4` (Mixed Berry Blue) by default, which provides good contrast for documentation.

---

## Advanced Features

### Containers (Grouping)

Containers group related elements and create visual hierarchy:

```d2
kubernetes: Kubernetes Cluster {
  style.fill: "#E3F2FD"

  production: Production Namespace {
    style.fill: "#E8F5E9"

    frontend: Frontend Pods {
      pod1: Pod 1
      pod2: Pod 2
      pod3: Pod 3
    }

    backend: Backend Pods {
      api1: API Pod 1
      api2: API Pod 2
    }

    data: Data Layer {
      postgres: PostgreSQL {
        shape: cylinder
      }
      redis: Redis {
        shape: cylinder
      }
    }
  }

  ingress: Ingress Controller {
    shape: hexagon
    style.fill: "#FFF3E0"
  }
}

kubernetes.ingress -> kubernetes.production.frontend.pod1
kubernetes.ingress -> kubernetes.production.frontend.pod2
kubernetes.production.backend.api1 -> kubernetes.production.data.postgres
kubernetes.production.backend.api1 -> kubernetes.production.data.redis
```

### Layers

Layers allow you to create multiple views of the same diagram:

```d2
layers: {
  overview: {
    title: High-Level Overview
    client -> server -> database
  }

  detailed: {
    title: Detailed View
    client: Web Client {
      browser: Browser
      mobile: Mobile App
    }

    server: Application Server {
      api: API Gateway
      auth: Auth Service
      core: Core Service
    }

    database: Data Layer {
      postgres: PostgreSQL
      redis: Redis
      s3: S3
    }
  }
}
```

### Sequence Diagrams

D2 supports sequence diagram syntax:

```d2
shape: sequence_diagram

client: Client
api: API Server
auth: Auth Service
db: Database

client -> api: POST /login
api -> auth: Validate credentials
auth -> db: Query user
db -> auth: User data
auth -> api: JWT token
api -> client: 200 OK + token

client -> api: GET /data (with token)
api -> auth: Verify token
auth -> api: Token valid
api -> db: Fetch data
db -> api: Data
api -> client: 200 OK + data
```

### Icons

D2 supports icons from various icon sets:

```d2
aws: AWS {
  icon: https://icons.terrastruct.com/aws%2F_Group%20Icons%2FAWS-Cloud-alt_light-bg.svg
}

docker: Docker {
  icon: https://icons.terrastruct.com/dev%2Fdocker.svg
}

kubernetes: Kubernetes {
  icon: https://icons.terrastruct.com/dev%2Fkubernetes.svg
}
```

### SQL Tables

D2 can render SQL table schemas:

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  username: varchar(255) {constraint: unique}
  email: varchar(255) {constraint: unique}
  created_at: timestamp
  updated_at: timestamp
}

orders: {
  shape: sql_table
  id: int {constraint: primary_key}
  user_id: int {constraint: foreign_key}
  total: decimal
  status: varchar(50)
  created_at: timestamp
}

users.id <-> orders.user_id
```

### Markdown in Labels

```d2
service: |md
  ## User Service

  **Responsibilities:**
  - User authentication
  - Profile management
  - Session handling

  **Tech Stack:**
  - Node.js
  - Express
  - PostgreSQL
|
```

### Tooltips

```d2
api: API Server {
  tooltip: |md
    **API Server**

    Main entry point for all client requests.
    Handles authentication and routing.
  |
}
```

---

## Example Diagrams

### Architecture Diagram

```d2
direction: down

title: ${{ values.name }} Architecture {
  shape: text
  near: top-center
  style.font-size: 24
  style.bold: true
}

clients: Clients {
  style.fill: "#E3F2FD"

  web: Web App {
    shape: rectangle
  }

  mobile: Mobile App {
    shape: rectangle
  }

  cli: CLI Tool {
    shape: rectangle
  }
}

gateway: API Gateway {
  shape: hexagon
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

services: Services {
  style.fill: "#E8F5E9"

  auth: Auth Service {
    shape: hexagon
  }

  users: User Service {
    shape: hexagon
  }

  orders: Order Service {
    shape: hexagon
  }

  notifications: Notification Service {
    shape: hexagon
  }
}

messaging: Event Bus {
  style.fill: "#F3E5F5"

  kafka: Kafka {
    shape: queue
  }
}

data: Data Layer {
  style.fill: "#FCE4EC"

  postgres: PostgreSQL {
    shape: cylinder
  }

  redis: Redis {
    shape: cylinder
  }

  elasticsearch: Elasticsearch {
    shape: cylinder
  }
}

external: External Services {
  style.fill: "#E0F7FA"

  email: Email Provider {
    shape: cloud
  }

  sms: SMS Provider {
    shape: cloud
  }

  payment: Payment Gateway {
    shape: cloud
  }
}

clients.web -> gateway
clients.mobile -> gateway
clients.cli -> gateway

gateway -> services.auth
gateway -> services.users
gateway -> services.orders

services.auth -> data.redis
services.users -> data.postgres
services.orders -> data.postgres
services.orders -> data.elasticsearch

services.orders -> messaging.kafka
services.notifications -> messaging.kafka

services.notifications -> external.email
services.notifications -> external.sms
services.orders -> external.payment
```

### Flow Diagram

```d2
direction: right

start: Start {
  shape: oval
  style.fill: "#E8F5E9"
}

receive: Receive Request {
  style.fill: "#E3F2FD"
}

validate: Validate Input {
  style.fill: "#E3F2FD"
}

valid_check: Valid? {
  shape: diamond
  style.fill: "#FFF3E0"
}

process: Process Data {
  style.fill: "#E3F2FD"
}

success_check: Success? {
  shape: diamond
  style.fill: "#FFF3E0"
}

store: Store Result {
  style.fill: "#E3F2FD"
}

notify: Send Notification {
  style.fill: "#E3F2FD"
}

error_response: Error Response {
  style.fill: "#FFEBEE"
}

success_response: Success Response {
  style.fill: "#E8F5E9"
}

end: End {
  shape: oval
  style.fill: "#F5F5F5"
}

start -> receive -> validate -> valid_check

valid_check -> process: Yes
valid_check -> error_response: No

process -> success_check

success_check -> store: Yes
success_check -> error_response: No

store -> notify -> success_response -> end
error_response -> end
```

### Sequence Diagram

```d2
shape: sequence_diagram

user: User
browser: Browser
api: API Server
auth: Auth Service
db: Database
cache: Cache

user -> browser: Click Login
browser -> api: POST /auth/login
api -> auth: Validate credentials

auth -> cache: Check rate limit
cache -> auth: OK

auth -> db: Query user
db -> auth: User record

auth -> auth: Verify password
auth -> auth: Generate JWT

auth -> cache: Store session
cache -> auth: OK

auth -> api: JWT Token
api -> browser: Set cookie + redirect
browser -> user: Dashboard
```

### CI/CD Pipeline

```d2
direction: right

source: Source {
  github: GitHub {
    icon: https://icons.terrastruct.com/dev%2Fgithub.svg
  }
}

build: Build Stage {
  style.fill: "#E3F2FD"

  checkout: Checkout
  deps: Install Deps
  compile: Compile
  unit_test: Unit Tests
}

quality: Quality Stage {
  style.fill: "#FFF3E0"

  lint: Linting
  security: Security Scan
  coverage: Coverage
}

deploy_staging: Staging {
  style.fill: "#E8F5E9"

  build_image: Build Image
  push_image: Push to Registry
  deploy: Deploy to Staging
  integration: Integration Tests
}

deploy_prod: Production {
  style.fill: "#F3E5F5"

  approval: Manual Approval {
    shape: diamond
  }
  deploy_prod: Deploy to Prod
  smoke: Smoke Tests
  monitor: Monitor
}

source.github -> build.checkout
build.checkout -> build.deps -> build.compile -> build.unit_test

build.unit_test -> quality.lint
quality.lint -> quality.security -> quality.coverage

quality.coverage -> deploy_staging.build_image
deploy_staging.build_image -> deploy_staging.push_image
deploy_staging.push_image -> deploy_staging.deploy
deploy_staging.deploy -> deploy_staging.integration

deploy_staging.integration -> deploy_prod.approval
deploy_prod.approval -> deploy_prod.deploy_prod: Approved
deploy_prod.deploy_prod -> deploy_prod.smoke -> deploy_prod.monitor
```

---

## Integration with TechDocs

### Plugin Configuration

D2 diagrams are rendered in TechDocs using the `mkdocs-d2` plugin. The configuration is specified in `mkdocs.yml`:

```yaml
site_name: ${{ values.name }}
site_description: ${{ values.description }}

nav:
  - Home: index.md
  - Architecture: architecture.md
  - Examples: examples.md

plugins:
  - techdocs-core
  - d2:
      theme: 4
```

### Adding Diagrams to Documentation

To add a D2 diagram to any markdown file, use a fenced code block:

````markdown
```d2
client -> server: Request
server -> database: Query
database -> server: Result
server -> client: Response
```
````

### Diagram Options

You can specify per-diagram options:

````markdown
```d2 layout=elk theme=1
complex_diagram: Complex Layout
another_element: Another Element
complex_diagram -> another_element
```
````

### Best Practices for TechDocs

1. **Keep diagrams focused**: Each diagram should illustrate one concept
2. **Use consistent styling**: Apply the same color scheme across diagrams
3. **Add context**: Include text descriptions around diagrams
4. **Version control**: Track diagram changes with code changes
5. **Review diagrams**: Include diagram updates in code reviews

---

## Troubleshooting

### Common Issues

#### Diagram Not Rendering

**Problem**: D2 code block shows as plain text.

**Solutions**:
- Verify the `d2` plugin is configured in `mkdocs.yml`
- Check that TechDocs builder has D2 installed
- Ensure code block uses correct language identifier: ` ```d2 `

#### Syntax Errors

**Problem**: Diagram fails to render with syntax error.

**Solutions**:
- Check for unclosed braces or quotes
- Verify shape/connection syntax
- Use the [D2 Playground](https://play.d2lang.com/) to test syntax

#### Layout Issues

**Problem**: Diagram layout is not as expected.

**Solutions**:
- Explicitly set `direction: down` or `direction: right`
- Use containers to group related elements
- Try different layout engines: `layout=elk` or `layout=dagre`

#### Styling Not Applied

**Problem**: Style properties are ignored.

**Solutions**:
- Use correct property names (e.g., `stroke-width` not `strokeWidth`)
- Ensure colors include quotes: `"#E3F2FD"`
- Check for typos in style block

### Debugging Tips

1. **Test in D2 Playground**: Validate syntax at [play.d2lang.com](https://play.d2lang.com/)
2. **Check logs**: Review TechDocs build logs for D2 errors
3. **Simplify**: Start with a minimal diagram and add complexity
4. **Format code**: Use `d2 fmt` to format D2 files

### Plugin Version Compatibility

Ensure your `mkdocs-d2` plugin version is compatible with your TechDocs setup:

| TechDocs Version | Recommended Plugin Version |
|------------------|---------------------------|
| 1.x | mkdocs-d2 >= 0.1.0 |
| Latest | mkdocs-d2 >= 1.0.0 |

---

## References

### Official Resources

- [D2 Official Documentation](https://d2lang.com/) - Complete language reference
- [D2 Playground](https://play.d2lang.com/) - Interactive diagram editor
- [D2 GitHub Repository](https://github.com/terrastruct/d2) - Source code and issues
- [D2 Tour](https://d2lang.com/tour/intro/) - Interactive tutorial

### Backstage Resources

- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/) - TechDocs documentation
- [TechDocs Customization](https://backstage.io/docs/features/techdocs/configuration) - Configuration options
- [mkdocs-d2 Plugin](https://github.com/landmaj/mkdocs-d2) - Plugin documentation

### Related Tools

| Tool | Description | Link |
|------|-------------|------|
| D2 CLI | Command-line tool for D2 | [Install](https://d2lang.com/tour/install/) |
| VS Code Extension | Syntax highlighting | [Marketplace](https://marketplace.visualstudio.com/items?itemName=terrastruct.d2) |
| mkdocs-d2 | MkDocs plugin | [PyPI](https://pypi.org/project/mkdocs-d2/) |
| Terrastruct | Commercial D2 editor | [terrastruct.com](https://terrastruct.com/) |

### Cheat Sheet

```d2
# Shapes
box                       # Default rectangle
box: Label                # With label
box { shape: cylinder }   # Database shape

# Connections
a -> b                    # Arrow
a <- b                    # Reverse
a <-> b                   # Bidirectional
a -- b                    # Line only
a -> b: label             # With label

# Styling
box.style.fill: "#E3F2FD"
box.style.stroke: "#1976D2"
box.style.stroke-width: 2

# Containers
outer: {
  inner: Nested
}

# Direction
direction: right          # or down, up, left

# Sequence diagrams
shape: sequence_diagram
a -> b: message
```

---

## Documentation Sections

- **[Architecture](architecture.md)** - System architecture diagrams and component views
- **[Examples](examples.md)** - D2 diagram examples and common patterns

---

*This documentation was generated for `${{ values.name }}` owned by `${{ values.owner }}`.*
