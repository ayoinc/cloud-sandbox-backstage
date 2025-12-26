# Architecture

## System Overview

```d2
direction: down

title: System Architecture {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
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

  api: API Server {
    shape: hexagon
  }

  worker: Background Worker {
    shape: hexagon
  }
}

data: Data Tier {
  style.fill: "#FCE4EC"

  db: Database {
    shape: cylinder
  }

  cache: Cache {
    shape: cylinder
  }
}

users -> lb: HTTPS
lb -> app.api
app.api -> data.db
app.api -> data.cache
app.worker -> data.db
```

## Component Diagram

```d2
direction: right

frontend: Frontend {
  style.fill: "#E3F2FD"

  web: Web App
  mobile: Mobile App
}

backend: Backend Services {
  style.fill: "#E8F5E9"

  api: API Gateway {
    shape: hexagon
  }

  auth: Auth Service {
    shape: hexagon
  }

  core: Core Service {
    shape: hexagon
  }
}

storage: Storage {
  style.fill: "#FFF3E0"

  postgres: PostgreSQL {
    shape: cylinder
  }

  redis: Redis {
    shape: cylinder
  }

  s3: Object Storage {
    shape: cylinder
  }
}

frontend.web -> backend.api
frontend.mobile -> backend.api
backend.api -> backend.auth
backend.api -> backend.core
backend.core -> storage.postgres
backend.auth -> storage.redis
backend.core -> storage.s3
```

## Data Flow

```d2
direction: right

input: Input {
  style.fill: "#E3F2FD"
}

validate: Validate {
  style.fill: "#FFF8E1"
}

process: Process {
  style.fill: "#E8F5E9"
}

store: Store {
  style.fill: "#FCE4EC"
}

notify: Notify {
  style.fill: "#F3E5F5"
}

input -> validate -> process -> store -> notify
```
