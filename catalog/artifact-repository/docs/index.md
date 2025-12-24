# Artifact Repository

Universal artifact management platform supporting Maven, npm, Docker, PyPI, NuGet, and generic artifact storage with Nexus Repository Manager.

## Quick Start

```bash
# Start Nexus with Docker
docker run -d -p 8081:8081 --name nexus \
  -v nexus-data:/nexus-data \
  sonatype/nexus3:3.66.0

# Wait for startup (check logs)
docker logs -f nexus

# Get initial admin password
docker exec nexus cat /nexus-data/admin.password

# Access UI
open http://localhost:8081

# Configure Maven settings
cat >> ~/.m2/settings.xml << 'EOF'
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>your-password</password>
    </server>
  </servers>
</settings>
EOF

# Deploy a Maven artifact
mvn deploy -DaltDeploymentRepository=nexus::default::http://localhost:8081/repository/maven-releases/
```

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Multi-Format Support** | Maven, npm, Docker, PyPI, NuGet, Helm, etc. | Single source of truth |
| **Proxy Repositories** | Cache external artifacts locally | Faster builds, offline access |
| **Hosted Repositories** | Store internal artifacts | Centralized artifact management |
| **Repository Groups** | Aggregate multiple repositories | Simplified configuration |
| **Access Control** | Role-based permissions | Secure artifact access |
| **Cleanup Policies** | Automatic artifact removal | Storage optimization |
| **Replication** | Sync artifacts across instances | High availability |
| **REST API** | Programmatic access | CI/CD integration |

## Supported Formats

| Format | Repository Types | Use Cases |
|--------|-----------------|-----------|
| **Maven** | Hosted, Proxy, Group | Java, Kotlin, Scala artifacts |
| **npm** | Hosted, Proxy, Group | Node.js packages |
| **Docker** | Hosted, Proxy, Group | Container images |
| **PyPI** | Hosted, Proxy, Group | Python packages |
| **NuGet** | Hosted, Proxy, Group | .NET packages |
| **Helm** | Hosted, Proxy | Kubernetes charts |
| **Raw** | Hosted, Proxy, Group | Generic files |
| **apt** | Hosted, Proxy | Debian packages |
| **yum** | Hosted, Proxy, Group | RPM packages |
| **Go** | Proxy | Go modules |
| **RubyGems** | Hosted, Proxy, Group | Ruby gems |

## Architecture

```d2
direction: down

title: Artifact Repository Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

clients: Clients {
  shape: rectangle
  style.fill: "#E3F2FD"
  
  maven: Maven
  npm: npm
  docker: Docker
  gradle: Gradle
}

nexus: Artifact Repository (Nexus) {
  shape: rectangle
  style.fill: "#FFF3E0"
  
  groups: Repository Groups {
    shape: rectangle
    style.fill: "#FFE0B2"
    
    maven_public: maven-public (Group) {
      style.fill: "#FFCC80"
    }
    npm_all: npm-all (Group) {
      style.fill: "#FFCC80"
    }
    docker_all: docker-all (Group) {
      style.fill: "#FFCC80"
    }
  }
  
  repos: Repositories {
    shape: rectangle
    style.fill: "#C8E6C9"
    
    hosted: Hosted {
      shape: cylinder
      style.fill: "#81C784"
      maven_releases: maven-releases
      maven_snapshots: maven-snapshots
      docker_private: docker-private
    }
    
    proxy: Proxy {
      shape: cylinder
      style.fill: "#4FC3F7"
      maven_central: maven-central
      npmjs: npmjs.org
      docker_hub: docker-hub
    }
  }
  
  storage: Storage Layer {
    shape: rectangle
    style.fill: "#E1BEE7"
    
    default_blob: Default Blob Store {
      shape: cylinder
      style.fill: "#CE93D8"
    }
    s3_blob: S3 Blob Store {
      shape: cylinder
      style.fill: "#CE93D8"
    }
  }
  
  services: Supporting Services {
    shape: rectangle
    style.fill: "#FFCDD2"
    
    scheduler: Scheduler (Cleanup)
    security: Security (LDAP/SAML)
    search: Search (OrientDB)
  }
}

remote: Remote Repositories {
  shape: cloud
  style.fill: "#B3E5FC"
  
  central: Maven Central
  npmjs_remote: npmjs.org
  dockerhub: Docker Hub
}

clients -> nexus.groups: fetch/push
nexus.groups -> nexus.repos.hosted: includes
nexus.groups -> nexus.repos.proxy: includes
nexus.repos.proxy -> remote: cache from
nexus.repos -> nexus.storage: stores in
```

## Repository Types

| Type | Description | Example |
|------|-------------|---------|
| **Hosted** | Stores internally published artifacts | maven-releases, docker-private |
| **Proxy** | Caches artifacts from remote repositories | maven-central, docker-hub |
| **Group** | Aggregates multiple repositories | maven-public, npm-all |

## Default Repositories

| Repository | Type | Format | Purpose |
|------------|------|--------|---------|
| maven-central | Proxy | Maven | Central Maven repository |
| maven-releases | Hosted | Maven | Internal release artifacts |
| maven-snapshots | Hosted | Maven | Internal snapshot artifacts |
| maven-public | Group | Maven | All Maven artifacts |
| nuget.org-proxy | Proxy | NuGet | NuGet.org cache |
| docker-hub | Proxy | Docker | Docker Hub cache |

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| Nexus Repository OSS | 3.66+ | Open source, full featured |
| Nexus Repository Pro | 3.66+ | Enterprise features |
| JFrog Artifactory OSS | 7.77+ | Alternative option |
| JFrog Artifactory Pro | 7.77+ | Enterprise alternative |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security
- [Usage](usage.md) - Client configuration and CI/CD integration
