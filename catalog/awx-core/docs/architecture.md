# Architecture

This page provides visual architecture diagrams for AWX using D2 declarative diagramming.

## System Architecture

The following diagram shows the high-level architecture of AWX deployed on Kubernetes:

```d2
direction: down

title: AWX Kubernetes Architecture {
  shape: text
  near: top-center
  style: {
    font-size: 24
    bold: true
  }
}

# External Access
users: Users {
  shape: person
}

ingress: Ingress Controller {
  shape: cloud
  style: {
    fill: "#E8F5E9"
  }
}

users -> ingress: HTTPS/WSS

# AWX Core Components
awx: AWX Cluster {
  style: {
    fill: "#E3F2FD"
    stroke: "#1976D2"
  }
  
  web: Web Pod {
    nginx: nginx {
      shape: hexagon
    }
    uwsgi: uwsgi/Django {
      shape: hexagon
    }
    nginx -> uwsgi
  }
  
  task: Task Pod {
    celery: Celery Workers {
      shape: hexagon
    }
    receptor: Receptor Mesh {
      shape: hexagon
    }
    dispatcher: Dispatcher {
      shape: hexagon
    }
  }
  
  ee: Execution Environment {
    style: {
      fill: "#FFF3E0"
    }
    runner: ansible-runner {
      shape: hexagon
    }
    collections: Collections {
      shape: cylinder
    }
    runner -> collections
  }
}

# Data Services
data: Data Services {
  style: {
    fill: "#FCE4EC"
    stroke: "#C2185B"
  }
  
  postgres: PostgreSQL {
    shape: cylinder
    style: {
      fill: "#336791"
      font-color: white
    }
  }
  
  redis: Redis {
    shape: cylinder
    style: {
      fill: "#DC382D"
      font-color: white
    }
  }
}

# Connections
ingress -> awx.web
awx.web -> awx.task: Job Queue
awx.task -> awx.ee: Execute Jobs
awx.web -> data.postgres: Read/Write
awx.task -> data.postgres: Job History
awx.task -> data.redis: Cache/Events
awx.web -> data.redis: WebSocket Events

# External Systems
targets: Managed Infrastructure {
  shape: cloud
  style: {
    fill: "#F3E5F5"
  }
}

awx.ee -> targets: SSH/WinRM
```

## Job Execution Flow

This diagram illustrates the flow of a job from creation to completion:

```d2
direction: right

title: Job Execution Pipeline {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
}

# Steps
launch: 1. Job Launch {
  style: {
    fill: "#E3F2FD"
  }
  user: User/API/Schedule
  create: Create Job
  queue: Queue to Celery
  
  user -> create -> queue
}

prep: 2. Pre-run Tasks {
  style: {
    fill: "#FFF8E1"
  }
  decrypt: Decrypt Credentials
  sync_proj: Sync Project
  sync_inv: Sync Inventory
  prep_ee: Prepare EE
  
  decrypt -> sync_proj -> sync_inv -> prep_ee
}

exec: 3. Execution {
  style: {
    fill: "#E8F5E9"
  }
  receptor: Receptor
  runner: ansible-runner
  playbook: Ansible Playbook
  stream: WebSocket Stream
  
  receptor -> runner -> playbook
  runner -> stream
}

post: 4. Post-run {
  style: {
    fill: "#F3E5F5"
  }
  store: Store Output
  notify: Send Notifications
  trigger: Trigger Workflows
  status: Update Status
  
  store -> notify -> trigger -> status
}

# Flow
launch -> prep -> exec -> post
```

## RBAC Model

The Role-Based Access Control model in AWX:

```d2
direction: down

title: AWX RBAC Model {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
}

# Organization hierarchy
org: Organization {
  shape: rectangle
  style: {
    fill: "#E3F2FD"
    stroke: "#1976D2"
    stroke-width: 2
  }
  
  teams: Teams {
    team1: Platform Team
    team2: DevOps Team
    team3: Security Team
  }
  
  users: Users {
    shape: person
  }
  
  teams -> users
}

# Resources
resources: Resources {
  style: {
    fill: "#FFF3E0"
  }
  
  projects: Projects {
    shape: page
  }
  inventories: Inventories {
    shape: cylinder
  }
  credentials: Credentials {
    shape: stored_data
  }
  templates: Job Templates {
    shape: document
  }
  workflows: Workflow Templates {
    shape: document
  }
}

# Roles
roles: Permission Roles {
  style: {
    fill: "#E8F5E9"
  }
  
  admin: Admin {
    style.fill: "#C8E6C9"
  }
  execute: Execute {
    style.fill: "#DCEDC8"
  }
  read: Read {
    style.fill: "#F0F4C3"
  }
  use: Use {
    style.fill: "#FFF9C4"
  }
}

# Connections
org -> resources: owns
org.teams -> roles: assigned
roles -> resources: grants access
```

## Receptor Mesh Network

For distributed execution across multiple sites:

```d2
direction: right

title: Receptor Mesh Topology {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
}

# Central AWX
central: Central Site {
  style: {
    fill: "#E3F2FD"
  }
  
  awx: AWX Controller {
    shape: hexagon
    style: {
      fill: "#1976D2"
      font-color: white
    }
  }
}

# Hop Nodes
hop1: Hop Node 1 {
  style: {
    fill: "#FFF3E0"
  }
  receptor1: Receptor {
    shape: hexagon
  }
}

hop2: Hop Node 2 {
  style: {
    fill: "#FFF3E0"
  }
  receptor2: Receptor {
    shape: hexagon
  }
}

# Remote Sites
site1: Site A {
  style: {
    fill: "#E8F5E9"
  }
  
  worker1: Execution Node {
    shape: hexagon
  }
  targets1: Servers {
    shape: cloud
  }
  
  worker1 -> targets1: SSH
}

site2: Site B {
  style: {
    fill: "#E8F5E9"
  }
  
  worker2: Execution Node {
    shape: hexagon
  }
  targets2: Servers {
    shape: cloud
  }
  
  worker2 -> targets2: SSH
}

site3: Site C {
  style: {
    fill: "#E8F5E9"
  }
  
  worker3: Execution Node {
    shape: hexagon
  }
  targets3: Servers {
    shape: cloud
  }
  
  worker3 -> targets3: SSH
}

# Mesh Connections
central.awx -> hop1.receptor1: Receptor Protocol
central.awx -> hop2.receptor2: Receptor Protocol
hop1.receptor1 -> site1.worker1
hop1.receptor1 -> site2.worker2
hop2.receptor2 -> site3.worker3
```

## Data Flow

How data flows through the AWX system:

```d2
direction: down

api: REST API {
  shape: rectangle
  style: {
    fill: "#E3F2FD"
  }
}

websocket: WebSocket {
  shape: rectangle
  style: {
    fill: "#E3F2FD"
  }
}

django: Django App {
  shape: hexagon
  style: {
    fill: "#4CAF50"
    font-color: white
  }
}

celery: Celery {
  shape: hexagon
  style: {
    fill: "#FF9800"
    font-color: white
  }
}

postgres: PostgreSQL {
  shape: cylinder
  style: {
    fill: "#336791"
    font-color: white
  }
}

redis: Redis {
  shape: cylinder
  style: {
    fill: "#DC382D"
    font-color: white
  }
}

receptor: Receptor {
  shape: hexagon
  style: {
    fill: "#9C27B0"
    font-color: white
  }
}

ee: Execution Environment {
  shape: rectangle
  style: {
    fill: "#FFF3E0"
  }
}

# Data flows
api -> django: HTTP Request
django -> postgres: CRUD Operations
django -> redis: Cache/Queue
django -> celery: Task Queue
celery -> receptor: Job Dispatch
receptor -> ee: Execute
ee -> receptor: Job Output
receptor -> redis: Events
redis -> websocket: Real-time Updates
websocket -> api: Stream to Client
```
