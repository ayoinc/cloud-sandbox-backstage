# ZooKeeper Ensemble Usage Guide

## Deployment Architecture

```d2
direction: right

title: ZooKeeper Deployment Options {
  shape: text
  near: top-center
  style.font-size: 24
}

docker: Docker Compose {
  style.fill: "#E3F2FD"
  
  single: Single Node\n(Development) {
    shape: rectangle
    style.fill: "#2196F3"
    style.font-color: white
  }
  
  cluster: 3-Node Ensemble\n(Production) {
    shape: rectangle
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

k8s: Kubernetes {
  style.fill: "#E8F5E9"
  
  helm: Helm Chart\n(Bitnami) {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  statefulset: StatefulSet\n(Manual) {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

clients: Client Libraries {
  style.fill: "#FFF3E0"
  
  python: kazoo\n(Python) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  java: Curator\n(Java) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  go: go-zookeeper\n(Go) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  node: node-zookeeper\n(Node.js) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
}

docker -> k8s: Scale Up {style.stroke-dash: 3}
k8s -> clients: Connect
```

## Docker Compose Deployment

### Development (Single Node)

```yaml
# docker-compose.yml
version: '3.8'

services:
  zookeeper:
    image: zookeeper:3.9
    container_name: zookeeper
    ports:
      - "2181:2181"
      - "8080:8080"
    environment:
      ZOO_MY_ID: 1
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 5
      ZOO_SYNC_LIMIT: 2
      ZOO_4LW_COMMANDS_WHITELIST: "mntr,ruok,stat,srvr,isro"
      ZOO_ADMINSERVER_ENABLED: "true"
    volumes:
      - zookeeper_data:/data
      - zookeeper_log:/datalog
    healthcheck:
      test: ["CMD", "zkServer.sh", "status"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  zookeeper_data:
  zookeeper_log:
```

### Production (3-Node Ensemble)

```yaml
# docker-compose.yml
version: '3.8'

services:
  zk1:
    image: zookeeper:3.9
    container_name: zk1
    hostname: zk1
    ports:
      - "2181:2181"
      - "7001:7000"
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=zk1:2888:3888;2181 server.2=zk2:2888:3888;2181 server.3=zk3:2888:3888;2181
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_MAX_CLIENT_CNXNS: 100
      ZOO_4LW_COMMANDS_WHITELIST: "*"
      ZOO_CFG_EXTRA: "metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider metricsProvider.httpPort=7000"
    volumes:
      - zk1_data:/data
      - zk1_log:/datalog
    networks:
      - zk-net

  zk2:
    image: zookeeper:3.9
    container_name: zk2
    hostname: zk2
    ports:
      - "2182:2181"
      - "7002:7000"
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zk1:2888:3888;2181 server.2=zk2:2888:3888;2181 server.3=zk3:2888:3888;2181
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_MAX_CLIENT_CNXNS: 100
      ZOO_4LW_COMMANDS_WHITELIST: "*"
      ZOO_CFG_EXTRA: "metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider metricsProvider.httpPort=7000"
    volumes:
      - zk2_data:/data
      - zk2_log:/datalog
    networks:
      - zk-net

  zk3:
    image: zookeeper:3.9
    container_name: zk3
    hostname: zk3
    ports:
      - "2183:2181"
      - "7003:7000"
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zk1:2888:3888;2181 server.2=zk2:2888:3888;2181 server.3=zk3:2888:3888;2181
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_MAX_CLIENT_CNXNS: 100
      ZOO_4LW_COMMANDS_WHITELIST: "*"
      ZOO_CFG_EXTRA: "metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider metricsProvider.httpPort=7000"
    volumes:
      - zk3_data:/data
      - zk3_log:/datalog
    networks:
      - zk-net

volumes:
  zk1_data:
  zk1_log:
  zk2_data:
  zk2_log:
  zk3_data:
  zk3_log:

networks:
  zk-net:
    driver: bridge
```

## Kubernetes Deployment

### Helm Chart Installation

```bash
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install ZooKeeper
helm install zookeeper bitnami/zookeeper \
  --namespace zookeeper \
  --create-namespace \
  --set replicaCount=3 \
  --set auth.enabled=false \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set resources.requests.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.limits.memory=2Gi \
  --set resources.limits.cpu=1000m \
  --set metrics.enabled=true
```

### Custom Values File

```yaml
# zookeeper-values.yaml
replicaCount: 3

image:
  registry: docker.io
  repository: bitnami/zookeeper
  tag: 3.9.2

auth:
  enabled: false

persistence:
  enabled: true
  storageClass: "standard"
  size: 20Gi

resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1000m

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring

podAntiAffinity: hard

nodeSelector:
  node-role: data

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "zookeeper"
    effect: "NoSchedule"

configuration: |
  tickTime=2000
  initLimit=10
  syncLimit=5
  maxClientCnxns=100
  autopurge.snapRetainCount=5
  autopurge.purgeInterval=24
  4lw.commands.whitelist=mntr,ruok,stat,srvr,isro
  metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
  metricsProvider.httpPort=7000
```

```bash
# Install with custom values
helm install zookeeper bitnami/zookeeper \
  --namespace zookeeper \
  --create-namespace \
  -f zookeeper-values.yaml
```

### StatefulSet (Manual)

```yaml
# zookeeper-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
  namespace: zookeeper
spec:
  serviceName: zookeeper-headless
  replicas: 3
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: zookeeper
              topologyKey: kubernetes.io/hostname
      containers:
        - name: zookeeper
          image: zookeeper:3.9
          ports:
            - containerPort: 2181
              name: client
            - containerPort: 2888
              name: follower
            - containerPort: 3888
              name: election
            - containerPort: 7000
              name: metrics
          env:
            - name: ZOO_SERVERS
              value: "server.1=zookeeper-0.zookeeper-headless:2888:3888;2181 server.2=zookeeper-1.zookeeper-headless:2888:3888;2181 server.3=zookeeper-2.zookeeper-headless:2888:3888;2181"
            - name: ZOO_4LW_COMMANDS_WHITELIST
              value: "*"
          command:
            - bash
            - -c
            - |
              export ZOO_MY_ID=$((${HOSTNAME##*-}+1))
              exec zkServer.sh start-foreground
          resources:
            requests:
              memory: 1Gi
              cpu: 500m
            limits:
              memory: 2Gi
              cpu: 1000m
          volumeMounts:
            - name: data
              mountPath: /data
            - name: log
              mountPath: /datalog
          livenessProbe:
            exec:
              command:
                - zkServer.sh
                - status
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command:
                - bash
                - -c
                - "echo ruok | nc localhost 2181 | grep imok"
            initialDelaySeconds: 10
            periodSeconds: 5
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 10Gi
    - metadata:
        name: log
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper-headless
  namespace: zookeeper
spec:
  clusterIP: None
  selector:
    app: zookeeper
  ports:
    - port: 2181
      name: client
    - port: 2888
      name: follower
    - port: 3888
      name: election
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper
  namespace: zookeeper
spec:
  type: ClusterIP
  selector:
    app: zookeeper
  ports:
    - port: 2181
      name: client
```

## Client Examples

### Python (kazoo)

```python
# pip install kazoo

from kazoo.client import KazooClient
from kazoo.recipe.lock import Lock
from kazoo.recipe.election import Election
from kazoo.recipe.watchers import DataWatch
import json

# Connection
zk = KazooClient(hosts='localhost:2181,localhost:2182,localhost:2183')
zk.start()

# Basic CRUD operations
# Create
zk.ensure_path('/myapp')
zk.create('/myapp/config', b'{"setting": "value"}')

# Read
data, stat = zk.get('/myapp/config')
print(f"Data: {data.decode()}")
print(f"Version: {stat.version}")

# Update
zk.set('/myapp/config', b'{"setting": "new_value"}')

# List children
children = zk.get_children('/myapp')
print(f"Children: {children}")

# Delete
zk.delete('/myapp/config')

# Ephemeral node (service registration)
zk.create('/services/my-service/instance-1', 
          b'{"host": "10.0.0.1", "port": 8080}',
          ephemeral=True)

# Sequential node
zk.create('/queue/item-', b'task data', sequence=True)

# Watch for changes
@zk.DataWatch('/myapp/config')
def watch_config(data, stat):
    if data:
        print(f"Config changed: {data.decode()}")

# Distributed Lock
lock = Lock(zk, '/locks/my-resource')
with lock:
    print("Lock acquired, doing work...")

# Leader Election
election = Election(zk, '/election/my-service')

def leader_func():
    print("I am the leader!")
    # Do leader work
    
election.run(leader_func)

# Cleanup
zk.stop()
zk.close()
```

### Java (Curator)

```java
// Maven dependency
// <dependency>
//   <groupId>org.apache.curator</groupId>
//   <artifactId>curator-recipes</artifactId>
//   <version>5.6.0</version>
// </dependency>

import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.framework.recipes.locks.InterProcessMutex;
import org.apache.curator.framework.recipes.leader.LeaderSelector;
import org.apache.curator.framework.recipes.leader.LeaderSelectorListener;
import org.apache.curator.framework.recipes.cache.CuratorCache;
import org.apache.curator.retry.ExponentialBackoffRetry;
import org.apache.zookeeper.CreateMode;

public class ZooKeeperExample {
    public static void main(String[] args) throws Exception {
        // Create client
        CuratorFramework client = CuratorFrameworkFactory.builder()
            .connectString("localhost:2181,localhost:2182,localhost:2183")
            .sessionTimeoutMs(60000)
            .connectionTimeoutMs(15000)
            .retryPolicy(new ExponentialBackoffRetry(1000, 3))
            .namespace("myapp")
            .build();
        
        client.start();
        client.blockUntilConnected();
        
        // Create node
        client.create()
            .creatingParentsIfNeeded()
            .withMode(CreateMode.PERSISTENT)
            .forPath("/config", "value".getBytes());
        
        // Read node
        byte[] data = client.getData().forPath("/config");
        System.out.println("Data: " + new String(data));
        
        // Update node
        client.setData().forPath("/config", "new_value".getBytes());
        
        // Ephemeral node
        client.create()
            .withMode(CreateMode.EPHEMERAL)
            .forPath("/services/instance-1", "host:port".getBytes());
        
        // Watch with CuratorCache
        CuratorCache cache = CuratorCache.build(client, "/config");
        cache.listenable().addListener((type, oldData, data) -> {
            System.out.println("Event: " + type);
        });
        cache.start();
        
        // Distributed Lock
        InterProcessMutex lock = new InterProcessMutex(client, "/locks/resource");
        if (lock.acquire(10, TimeUnit.SECONDS)) {
            try {
                System.out.println("Lock acquired");
                // Do work
            } finally {
                lock.release();
            }
        }
        
        // Leader Election
        LeaderSelector selector = new LeaderSelector(client, "/election/leader",
            new LeaderSelectorListener() {
                @Override
                public void takeLeadership(CuratorFramework client) throws Exception {
                    System.out.println("I am the leader!");
                    Thread.sleep(Long.MAX_VALUE); // Hold leadership
                }
                
                @Override
                public void stateChanged(CuratorFramework client, ConnectionState state) {
                    System.out.println("State changed: " + state);
                }
            });
        selector.autoRequeue();
        selector.start();
        
        // Cleanup
        client.close();
    }
}
```

### Go (go-zookeeper)

```go
// go get github.com/go-zookeeper/zk

package main

import (
    "fmt"
    "log"
    "time"
    
    "github.com/go-zookeeper/zk"
)

func main() {
    // Connect
    servers := []string{"localhost:2181", "localhost:2182", "localhost:2183"}
    conn, _, err := zk.Connect(servers, time.Second*5)
    if err != nil {
        log.Fatal(err)
    }
    defer conn.Close()
    
    // Create node
    path := "/myapp/config"
    data := []byte(`{"setting": "value"}`)
    acl := zk.WorldACL(zk.PermAll)
    
    // Create parent path first
    _, err = conn.Create("/myapp", nil, 0, acl)
    if err != nil && err != zk.ErrNodeExists {
        log.Fatal(err)
    }
    
    _, err = conn.Create(path, data, 0, acl)
    if err != nil && err != zk.ErrNodeExists {
        log.Fatal(err)
    }
    
    // Read node
    data, stat, err := conn.Get(path)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Data: %s, Version: %d\n", string(data), stat.Version)
    
    // Update node
    _, err = conn.Set(path, []byte(`{"setting": "new_value"}`), stat.Version)
    if err != nil {
        log.Fatal(err)
    }
    
    // Watch for changes
    data, stat, watchCh, err := conn.GetW(path)
    if err != nil {
        log.Fatal(err)
    }
    
    go func() {
        for event := range watchCh {
            fmt.Printf("Event: %v\n", event)
        }
    }()
    
    // Ephemeral node
    ephPath, err := conn.CreateProtectedEphemeralSequential(
        "/services/instance-",
        []byte("host:port"),
        acl,
    )
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Created ephemeral: %s\n", ephPath)
    
    // List children
    children, _, err := conn.Children("/myapp")
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Children: %v\n", children)
    
    // Simple lock implementation
    lockPath := "/locks/my-resource"
    lock := zk.NewLock(conn, lockPath, acl)
    err = lock.Lock()
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println("Lock acquired")
    // Do work
    lock.Unlock()
    
    // Keep running
    select {}
}
```

### Node.js (node-zookeeper-client)

```javascript
// npm install node-zookeeper-client

const zookeeper = require('node-zookeeper-client');

// Connect
const client = zookeeper.createClient('localhost:2181,localhost:2182,localhost:2183', {
    sessionTimeout: 30000,
    spinDelay: 1000,
    retries: 3
});

client.once('connected', async () => {
    console.log('Connected to ZooKeeper');
    
    // Create node
    client.create('/myapp/config', 
        Buffer.from(JSON.stringify({ setting: 'value' })),
        zookeeper.CreateMode.PERSISTENT,
        (error, path) => {
            if (error) {
                if (error.getCode() !== zookeeper.Exception.NODE_EXISTS) {
                    console.error(error);
                }
            } else {
                console.log('Created: %s', path);
            }
        }
    );
    
    // Read node
    client.getData('/myapp/config', (event) => {
        console.log('Watch event:', event);
    }, (error, data, stat) => {
        if (error) {
            console.error(error);
            return;
        }
        console.log('Data: %s, Version: %d', data.toString(), stat.version);
    });
    
    // Update node
    client.setData('/myapp/config', 
        Buffer.from(JSON.stringify({ setting: 'new_value' })),
        -1, // any version
        (error, stat) => {
            if (error) {
                console.error(error);
                return;
            }
            console.log('Updated, new version: %d', stat.version);
        }
    );
    
    // Ephemeral node (service registration)
    client.create('/services/my-service-',
        Buffer.from(JSON.stringify({ host: 'localhost', port: 8080 })),
        zookeeper.CreateMode.EPHEMERAL_SEQUENTIAL,
        (error, path) => {
            if (error) {
                console.error(error);
            } else {
                console.log('Registered service: %s', path);
            }
        }
    );
    
    // List children
    client.getChildren('/myapp', (event) => {
        console.log('Children watch:', event);
    }, (error, children, stat) => {
        if (error) {
            console.error(error);
            return;
        }
        console.log('Children: %s', children);
    });
});

client.connect();
```

## Common Recipes

### Service Discovery

```python
from kazoo.client import KazooClient
import json
import socket

class ServiceRegistry:
    def __init__(self, zk_hosts, service_name):
        self.zk = KazooClient(hosts=zk_hosts)
        self.zk.start()
        self.service_name = service_name
        self.base_path = f'/services/{service_name}'
        self.zk.ensure_path(self.base_path)
        self.instance_path = None
    
    def register(self, host, port, metadata=None):
        """Register this service instance"""
        data = {
            'host': host,
            'port': port,
            'metadata': metadata or {}
        }
        self.instance_path = self.zk.create(
            f'{self.base_path}/instance-',
            json.dumps(data).encode(),
            ephemeral=True,
            sequence=True
        )
        return self.instance_path
    
    def discover(self):
        """Discover all instances of this service"""
        instances = []
        children = self.zk.get_children(self.base_path)
        for child in children:
            data, _ = self.zk.get(f'{self.base_path}/{child}')
            instances.append(json.loads(data.decode()))
        return instances
    
    def watch_instances(self, callback):
        """Watch for instance changes"""
        @self.zk.ChildrenWatch(self.base_path)
        def watch(children):
            instances = self.discover()
            callback(instances)
    
    def deregister(self):
        """Deregister this instance"""
        if self.instance_path:
            self.zk.delete(self.instance_path)

# Usage
registry = ServiceRegistry('localhost:2181', 'my-api')

# Register
registry.register('10.0.0.1', 8080, {'version': '1.0'})

# Discover
instances = registry.discover()
print(f"Available instances: {instances}")

# Watch
def on_change(instances):
    print(f"Instances changed: {instances}")

registry.watch_instances(on_change)
```

### Distributed Configuration

```python
from kazoo.client import KazooClient
import json

class DistributedConfig:
    def __init__(self, zk_hosts, app_name):
        self.zk = KazooClient(hosts=zk_hosts)
        self.zk.start()
        self.app_name = app_name
        self.base_path = f'/config/{app_name}'
        self.zk.ensure_path(self.base_path)
        self.watchers = {}
    
    def set(self, key, value):
        """Set configuration value"""
        path = f'{self.base_path}/{key}'
        data = json.dumps(value).encode()
        
        if self.zk.exists(path):
            self.zk.set(path, data)
        else:
            self.zk.create(path, data)
    
    def get(self, key, default=None):
        """Get configuration value"""
        path = f'{self.base_path}/{key}'
        if self.zk.exists(path):
            data, _ = self.zk.get(path)
            return json.loads(data.decode())
        return default
    
    def get_all(self):
        """Get all configuration"""
        config = {}
        children = self.zk.get_children(self.base_path)
        for key in children:
            config[key] = self.get(key)
        return config
    
    def watch(self, key, callback):
        """Watch for configuration changes"""
        path = f'{self.base_path}/{key}'
        
        @self.zk.DataWatch(path)
        def watcher(data, stat):
            if data:
                value = json.loads(data.decode())
                callback(key, value)
        
        self.watchers[key] = watcher

# Usage
config = DistributedConfig('localhost:2181', 'my-app')

# Set values
config.set('database', {'host': 'db.example.com', 'port': 5432})
config.set('cache_ttl', 300)
config.set('feature_flags', {'dark_mode': True, 'beta_features': False})

# Get values
db_config = config.get('database')
print(f"Database: {db_config}")

# Watch for changes
def on_config_change(key, value):
    print(f"Config '{key}' changed to: {value}")

config.watch('feature_flags', on_config_change)
```

### Leader Election

```python
from kazoo.client import KazooClient
from kazoo.recipe.election import Election
import socket
import threading

class LeaderElection:
    def __init__(self, zk_hosts, election_path):
        self.zk = KazooClient(hosts=zk_hosts)
        self.zk.start()
        self.election = Election(self.zk, election_path)
        self.is_leader = False
        self.hostname = socket.gethostname()
    
    def run_for_leader(self, leader_func, follower_func=None):
        """Run for leader position"""
        def on_leader():
            self.is_leader = True
            print(f"{self.hostname}: I am now the leader!")
            leader_func()
        
        # Start election in background
        thread = threading.Thread(target=self.election.run, args=(on_leader,))
        thread.daemon = True
        thread.start()
        
        # Run follower logic while not leader
        if follower_func:
            while not self.is_leader:
                follower_func()
    
    def get_leader(self):
        """Get current leader"""
        contenders = self.election.contenders()
        return contenders[0] if contenders else None

# Usage
def leader_work():
    while True:
        print("Doing leader work...")
        time.sleep(5)

def follower_work():
    print("Waiting to become leader...")
    time.sleep(2)

election = LeaderElection('localhost:2181', '/election/my-service')
election.run_for_leader(leader_work, follower_work)
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused | ZooKeeper not running | Check `zkServer.sh status`, verify port 2181 |
| Session expired | Network issues or long GC pauses | Increase session timeout, tune JVM |
| No quorum | Too many nodes down | Ensure majority of nodes are running |
| Leader election stuck | Network partition | Check connectivity between nodes |
| Disk full | Too many snapshots/logs | Enable autopurge or manually clean |
| High latency | Disk I/O bottleneck | Use SSD, separate log disk |
| Too many connections | Connection leak | Increase `maxClientCnxns`, fix client code |
| Watch limit exceeded | Too many watches | Consolidate watches, use CuratorCache |

### Diagnostic Commands

```bash
# Check server status
docker exec zk1 zkServer.sh status

# View server configuration
echo conf | nc localhost 2181

# Check if server is up
echo ruok | nc localhost 2181

# Get server statistics
echo stat | nc localhost 2181

# Get detailed monitoring info
echo mntr | nc localhost 2181

# List all watches
echo wchs | nc localhost 2181

# List all connections
echo cons | nc localhost 2181

# Check if read-only mode
echo isro | nc localhost 2181

# Force snapshot
echo "snapshot" | nc localhost 2181
```

### Log Analysis

```bash
# View recent logs
docker logs --tail 100 zk1

# Search for errors
docker logs zk1 2>&1 | grep -i error

# Watch logs in real-time
docker logs -f zk1

# Check connection events
docker logs zk1 2>&1 | grep -i "session\|connect"

# Check leader election
docker logs zk1 2>&1 | grep -i "leader\|election"
```

### Recovery Procedures

```bash
# Restart single node
docker restart zk1

# Rolling restart (one at a time)
for node in zk1 zk2 zk3; do
  docker restart $node
  sleep 30  # Wait for sync
  echo "ruok" | nc ${node} 2181  # Verify
done

# Force leader re-election
# Stop current leader
docker stop zk1
# Wait for new leader
sleep 10
# Start old leader as follower
docker start zk1

# Clean corrupted data (CAUTION: data loss)
docker stop zk1
docker exec zk1 rm -rf /data/version-2/*
docker start zk1
```

## Best Practices

### Design Guidelines

1. **Use odd number of nodes** - 3 for most cases, 5 for high availability
2. **Separate data and log disks** - Use SSD for transaction logs
3. **Keep znodes small** - Less than 1MB, ideally under 1KB
4. **Limit watch usage** - Consolidate watches, don't watch every node
5. **Use ephemeral nodes for service registration** - Auto-cleanup on disconnect
6. **Implement proper retry logic** - Handle connection failures gracefully

### Security Checklist

- [ ] Enable SASL authentication
- [ ] Configure TLS for client connections
- [ ] Set appropriate ACLs on znodes
- [ ] Restrict network access (firewall rules)
- [ ] Use dedicated service accounts
- [ ] Disable 4-letter commands in production (or whitelist only needed)
- [ ] Enable audit logging

### Monitoring Checklist

- [ ] Monitor outstanding requests
- [ ] Alert on high latency (> 100ms average)
- [ ] Track connection count
- [ ] Monitor disk usage
- [ ] Set up health checks
- [ ] Monitor leader elections
- [ ] Track synced followers

### Operational Checklist

- [ ] Configure autopurge for snapshots
- [ ] Set up regular backups
- [ ] Document recovery procedures
- [ ] Test failover scenarios
- [ ] Implement rolling upgrade process
- [ ] Configure proper JVM heap size

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and configuration details
