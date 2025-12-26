# D2 Diagramming Guide for TechDocs

This guide explains how to use D2 declarative diagramming in your Backstage TechDocs documentation.

---

## 1. Overview

### What is D2?

D2 is a modern, declarative diagramming language that turns text descriptions into professional diagrams. It's designed to be:

- **Readable**: Syntax is intuitive and easy to learn
- **Version-controlled**: Diagrams live alongside your code
- **Themeable**: Consistent styling across all diagrams
- **Fast**: Renders diagrams in milliseconds

### Why D2 for TechDocs?

| Feature           | ASCII Art | Mermaid   | D2        |
| ----------------- | --------- | --------- | --------- |
| Visual Quality    | Low       | Medium    | High      |
| Styling Options   | None      | Limited   | Extensive |
| Learning Curve    | Easy      | Medium    | Easy      |
| Layout Control    | Manual    | Automatic | Both      |
| Container Support | No        | Limited   | Full      |
| Dark Mode         | No        | Yes       | Yes       |

## 2. Getting Started

### Enable D2 in Your Component

Add the D2 plugin to your `mkdocs.yml`:

```yaml
site_name: My Component
site_description: Component documentation

nav:
  - Home: index.md
  - Architecture: architecture.md

plugins:
  - techdocs-core
  - d2
```

### Basic Syntax

Create diagrams using fenced code blocks with the `d2` language identifier:

````markdown
```d2
# Basic connection
server -> database: SQL queries
```
````

## 3. Core Concepts

### Shapes

D2 supports many shape types:

```d2
# Default rectangle
default_shape: Default Shape

# Explicit shapes
rect: Rectangle {
  shape: rectangle
}

oval: Oval {
  shape: oval
}

cylinder: Database {
  shape: cylinder
}

hexagon: Service {
  shape: hexagon
}

cloud: Cloud Provider {
  shape: cloud
}

person: User {
  shape: person
}

page: Document {
  shape: page
}

queue: Message Queue {
  shape: queue
}
```

### Connections

Connect shapes with arrows:

```d2
# Simple connection
a -> b

# Labeled connection
client -> server: HTTP Request

# Bidirectional
api <-> database: CRUD

# Dotted line
service1 -- service2: async {
  style.stroke-dash: 3
}
```

### Direction

Control the layout direction:

```d2
direction: right  # left, right, up, down

step1: Start
step2: Process
step3: End

step1 -> step2 -> step3
```

### Containers (Nested Shapes)

Group related elements:

```d2
kubernetes: Kubernetes Cluster {
  namespace: Production Namespace {
    pod1: API Pod
    pod2: Worker Pod
  }

  ingress: Ingress Controller
}

kubernetes.ingress -> kubernetes.namespace.pod1
```

## 4. Styling

### Colors and Fills

```d2
primary: Primary Service {
  style: {
    fill: "#E3F2FD"
    stroke: "#1976D2"
    stroke-width: 2
  }
}

warning: Warning Box {
  style: {
    fill: "#FFF3E0"
    stroke: "#FF9800"
  }
}

success: Success Box {
  style: {
    fill: "#E8F5E9"
    stroke: "#4CAF50"
  }
}

error: Error State {
  style: {
    fill: "#FFEBEE"
    stroke: "#F44336"
  }
}
```

### Text Styling

```d2
title: Diagram Title {
  shape: text
  style: {
    font-size: 24
    bold: true
  }
}

subtitle: Supporting text {
  shape: text
  style: {
    font-size: 14
    italic: true
  }
}
```

### Connection Styling

```d2
a -> b: solid line
c -> d: dashed {
  style.stroke-dash: 5
}
e -> f: thick {
  style.stroke-width: 3
}
g -> h: colored {
  style.stroke: "#FF5722"
}
```

## 5. Common Patterns

### Architecture Diagram

```d2
direction: down

title: System Architecture {
  shape: text
  near: top-center
  style.font-size: 20
}

users: Users {
  shape: person
}

lb: Load Balancer {
  shape: cloud
  style.fill: "#E3F2FD"
}

app: Application Tier {
  style.fill: "#E8F5E9"

  api1: API Server 1 {
    shape: hexagon
  }
  api2: API Server 2 {
    shape: hexagon
  }
}

data: Data Tier {
  style.fill: "#FFF3E0"

  db: PostgreSQL {
    shape: cylinder
  }
  cache: Redis {
    shape: cylinder
  }
}

users -> lb: HTTPS
lb -> app.api1
lb -> app.api2
app.api1 -> data.db
app.api2 -> data.db
app.api1 -> data.cache
app.api2 -> data.cache
```

### Sequence Flow

```d2
direction: right

step1: 1. Request {
  style.fill: "#E3F2FD"
}
step2: 2. Validate {
  style.fill: "#FFF8E1"
}
step3: 3. Process {
  style.fill: "#E8F5E9"
}
step4: 4. Respond {
  style.fill: "#F3E5F5"
}

step1 -> step2 -> step3 -> step4
```

### Network Topology

```d2
internet: Internet {
  shape: cloud
}

dmz: DMZ {
  style.fill: "#FFECB3"

  firewall: Firewall {
    shape: hexagon
  }

  waf: WAF {
    shape: hexagon
  }
}

internal: Internal Network {
  style.fill: "#C8E6C9"

  app: Application Servers
  db: Database Servers
}

internet -> dmz.firewall -> dmz.waf -> internal.app -> internal.db
```

### Microservices

```d2
direction: right

gateway: API Gateway {
  shape: hexagon
  style.fill: "#E3F2FD"
}

services: Services {
  style.fill: "#F5F5F5"

  users: User Service {
    shape: hexagon
  }
  orders: Order Service {
    shape: hexagon
  }
  payments: Payment Service {
    shape: hexagon
  }
}

messaging: Event Bus {
  kafka: Kafka {
    shape: queue
    style.fill: "#FFE0B2"
  }
}

gateway -> services.users
gateway -> services.orders
gateway -> services.payments

services.users -> messaging.kafka
services.orders -> messaging.kafka
services.payments -> messaging.kafka
```

## 6. Best Practices

### Keep Diagrams Simple

- Focus on one concept per diagram
- Limit to 10-15 shapes maximum
- Use containers to group related items
- Add meaningful labels to connections

### Use Consistent Styling

Create a color palette for your organization:

| Purpose      | Fill Color | Stroke Color |
| ------------ | ---------- | ------------ |
| Primary/API  | `#E3F2FD`  | `#1976D2`    |
| Data/Storage | `#FCE4EC`  | `#C2185B`    |
| Processing   | `#E8F5E9`  | `#388E3C`    |
| External     | `#FFF3E0`  | `#FF9800`    |
| Warning      | `#FFECB3`  | `#FFA000`    |
| Error        | `#FFCDD2`  | `#D32F2F`    |

### Name Things Meaningfully

```d2
# Good
users: User Service
orders: Order Service
users -> orders: "Get user orders"

# Avoid
a: A
b: B
a -> b: connection
```

### Use Direction Wisely

- `direction: down` for hierarchies and data flow
- `direction: right` for sequences and timelines
- `direction: up` for bottom-up architectures

## 7. Migrating from ASCII Art

### Before (ASCII)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────►│  Server  │────►│ Database │
└──────────┘     └──────────┘     └──────────┘
```

### After (D2)

```d2
direction: right

client: Client {
  shape: rectangle
  style.fill: "#E3F2FD"
}

server: Server {
  shape: hexagon
  style.fill: "#E8F5E9"
}

database: Database {
  shape: cylinder
  style.fill: "#FCE4EC"
}

client -> server: HTTP
server -> database: SQL
```

## 8. Troubleshooting

### Common Issues

| Problem               | Solution                               |
| --------------------- | -------------------------------------- |
| Diagram not rendering | Check mkdocs.yml has `- d2` in plugins |
| Build fails           | Verify D2 is installed in container    |
| Labels not showing    | Ensure quotes around multi-word labels |
| Layout looks wrong    | Try different `direction` values       |

### Validation

Test your diagrams locally:

```bash
# Install D2 CLI
curl -fsSL https://d2lang.com/install.sh | sh

# Render a single diagram
d2 input.d2 output.svg

# Watch mode for live preview
d2 --watch input.d2 output.svg
```

## 9. Resources

- [D2 Official Documentation](https://d2lang.com/)
- [D2 Playground](https://play.d2lang.com/)
- [D2 GitHub Repository](https://github.com/terrastruct/d2)
- [mkdocs-d2-plugin](https://pypi.org/project/mkdocs-d2-plugin/)

---

_Last Updated: 2025-12-23_
