# D2 Diagram Examples

This page provides examples of common D2 diagram patterns.

## Basic Connections

```d2
a -> b: Simple connection
c <-> d: Bidirectional
e -- f: No arrow
```

## Shapes

```d2
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

cloud: Cloud {
  shape: cloud
}

person: User {
  shape: person
}

page: Document {
  shape: page
}

queue: Queue {
  shape: queue
}
```

## Containers

```d2
kubernetes: Kubernetes Cluster {
  style.fill: "#E3F2FD"
  
  namespace: Production {
    style.fill: "#E8F5E9"
    
    deployment: Deployment {
      pod1: Pod 1
      pod2: Pod 2
    }
  }
  
  ingress: Ingress Controller {
    shape: hexagon
  }
}

kubernetes.ingress -> kubernetes.namespace.deployment.pod1
kubernetes.ingress -> kubernetes.namespace.deployment.pod2
```

## Styling Examples

```d2
primary: Primary {
  style: {
    fill: "#E3F2FD"
    stroke: "#1976D2"
    stroke-width: 2
  }
}

success: Success {
  style: {
    fill: "#E8F5E9"
    stroke: "#388E3C"
    stroke-width: 2
  }
}

warning: Warning {
  style: {
    fill: "#FFF3E0"
    stroke: "#FF9800"
    stroke-width: 2
  }
}

error: Error {
  style: {
    fill: "#FFEBEE"
    stroke: "#D32F2F"
    stroke-width: 2
  }
}
```

## Microservices Pattern

```d2
direction: down

gateway: API Gateway {
  shape: hexagon
  style.fill: "#E3F2FD"
}

services: Microservices {
  style.fill: "#F5F5F5"
  
  users: User Service {
    shape: hexagon
    style.fill: "#E8F5E9"
  }
  
  orders: Order Service {
    shape: hexagon
    style.fill: "#E8F5E9"
  }
  
  payments: Payment Service {
    shape: hexagon
    style.fill: "#E8F5E9"
  }
  
  inventory: Inventory Service {
    shape: hexagon
    style.fill: "#E8F5E9"
  }
}

messaging: Event Bus {
  style.fill: "#FFF3E0"
  
  kafka: Kafka {
    shape: queue
  }
}

databases: Databases {
  style.fill: "#FCE4EC"
  
  users_db: Users DB {
    shape: cylinder
  }
  
  orders_db: Orders DB {
    shape: cylinder
  }
  
  payments_db: Payments DB {
    shape: cylinder
  }
  
  inventory_db: Inventory DB {
    shape: cylinder
  }
}

gateway -> services.users
gateway -> services.orders
gateway -> services.payments
gateway -> services.inventory

services.users -> databases.users_db
services.orders -> databases.orders_db
services.payments -> databases.payments_db
services.inventory -> databases.inventory_db

services.orders -> messaging.kafka: "Order Events"
services.payments -> messaging.kafka: "Payment Events"
services.inventory -> messaging.kafka: "Inventory Events"
```

## Pipeline Pattern

```d2
direction: right

source: Source Code {
  style.fill: "#E3F2FD"
}

build: Build {
  style.fill: "#FFF8E1"
}

test: Test {
  style.fill: "#E8F5E9"
}

scan: Security Scan {
  style.fill: "#F3E5F5"
}

deploy: Deploy {
  style.fill: "#FFECB3"
}

monitor: Monitor {
  style.fill: "#B3E5FC"
}

source -> build -> test -> scan -> deploy -> monitor
```
