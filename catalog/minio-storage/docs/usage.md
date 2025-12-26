# MinIO Storage Usage Guide

## Docker Compose Deployment

### Development (Single Node)

```yaml
# docker-compose.yml
version: '3.8'

services:
  minio:
    image: minio/minio:latest
    container_name: minio
    ports:
      - '9000:9000'
      - '9001:9001'
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:9000/minio/health/live']
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  minio_data:
```

### Production (Distributed - 4 Nodes)

```yaml
# docker-compose.yml
version: '3.8'

x-minio-common: &minio-common
  image: minio/minio:latest
  command: server --console-address ":9001" http://minio{1...4}/data{1...2}
  environment:
    MINIO_ROOT_USER: ${MINIO_ROOT_USER:-admin}
    MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minio_secret_key}
    MINIO_PROMETHEUS_AUTH_TYPE: public
  healthcheck:
    test: ['CMD', 'curl', '-f', 'http://localhost:9000/minio/health/live']
    interval: 30s
    timeout: 20s
    retries: 3
  networks:
    - minio-net

services:
  minio1:
    <<: *minio-common
    hostname: minio1
    volumes:
      - minio1-data1:/data1
      - minio1-data2:/data2

  minio2:
    <<: *minio-common
    hostname: minio2
    volumes:
      - minio2-data1:/data1
      - minio2-data2:/data2

  minio3:
    <<: *minio-common
    hostname: minio3
    volumes:
      - minio3-data1:/data1
      - minio3-data2:/data2

  minio4:
    <<: *minio-common
    hostname: minio4
    volumes:
      - minio4-data1:/data1
      - minio4-data2:/data2

  nginx:
    image: nginx:alpine
    hostname: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - '9000:9000'
      - '9001:9001'
    depends_on:
      - minio1
      - minio2
      - minio3
      - minio4
    networks:
      - minio-net

volumes:
  minio1-data1:
  minio1-data2:
  minio2-data1:
  minio2-data2:
  minio3-data1:
  minio3-data2:
  minio4-data1:
  minio4-data2:

networks:
  minio-net:
    driver: bridge
```

### Nginx Load Balancer Configuration

```nginx
# nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    # Ignore MinIO's Connection header
    ignore_invalid_headers off;
    # Allow any size file upload
    client_max_body_size 0;
    # Disable buffering
    proxy_buffering off;
    proxy_request_buffering off;

    upstream minio_s3 {
        least_conn;
        server minio1:9000;
        server minio2:9000;
        server minio3:9000;
        server minio4:9000;
    }

    upstream minio_console {
        least_conn;
        server minio1:9001;
        server minio2:9001;
        server minio3:9001;
        server minio4:9001;
    }

    server {
        listen 9000;
        listen [::]:9000;
        server_name localhost;

        location / {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 300;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            chunked_transfer_encoding off;

            proxy_pass http://minio_s3;
        }
    }

    server {
        listen 9001;
        listen [::]:9001;
        server_name localhost;

        location / {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-NginX-Proxy true;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_connect_timeout 300;
            chunked_transfer_encoding off;

            proxy_pass http://minio_console;
        }
    }
}
```

## Kubernetes Deployment

### Helm Chart Installation

```bash
# Add MinIO Operator repo
helm repo add minio https://operator.min.io/
helm repo update

# Install MinIO Operator
helm install minio-operator minio/operator \
  --namespace minio-operator \
  --create-namespace

# Create tenant
kubectl apply -f minio-tenant.yaml
```

### MinIO Tenant Configuration

```yaml
# minio-tenant.yaml
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: minio
  namespace: minio-tenant
spec:
  image: minio/minio:latest
  imagePullPolicy: IfNotPresent

  pools:
    - servers: 4
      name: pool-0
      volumesPerServer: 4
      volumeClaimTemplate:
        metadata:
          name: data
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 100Gi
          storageClassName: standard
      resources:
        requests:
          memory: 2Gi
          cpu: 1000m
        limits:
          memory: 4Gi
          cpu: 2000m
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  v1.min.io/tenant: minio
              topologyKey: kubernetes.io/hostname

  mountPath: /export

  requestAutoCert: true

  configuration:
    name: minio-config

  users:
    - name: minio-user-0

  buckets:
    - name: techdocs
    - name: backstage
    - name: artifacts

  features:
    enableSFTP: false

  prometheusOperator: true
---
apiVersion: v1
kind: Secret
metadata:
  name: minio-config
  namespace: minio-tenant
type: Opaque
stringData:
  config.env: |
    export MINIO_ROOT_USER=admin
    export MINIO_ROOT_PASSWORD=minio_secret_key
    export MINIO_PROMETHEUS_AUTH_TYPE=public
---
apiVersion: v1
kind: Secret
metadata:
  name: minio-user-0
  namespace: minio-tenant
type: Opaque
stringData:
  CONSOLE_ACCESS_KEY: backstage
  CONSOLE_SECRET_KEY: backstage_secret_key
```

### Manual StatefulSet Deployment

```yaml
# minio-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: minio
  namespace: minio
spec:
  serviceName: minio-headless
  replicas: 4
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: minio
              topologyKey: kubernetes.io/hostname
      containers:
        - name: minio
          image: minio/minio:latest
          args:
            - server
            - http://minio-{0...3}.minio-headless.minio.svc.cluster.local/data
            - --console-address
            - ':9001'
          env:
            - name: MINIO_ROOT_USER
              valueFrom:
                secretKeyRef:
                  name: minio-secret
                  key: root-user
            - name: MINIO_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: minio-secret
                  key: root-password
          ports:
            - containerPort: 9000
              name: api
            - containerPort: 9001
              name: console
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              memory: 1Gi
              cpu: 500m
            limits:
              memory: 2Gi
              cpu: 1000m
          livenessProbe:
            httpGet:
              path: /minio/health/live
              port: 9000
            initialDelaySeconds: 120
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /minio/health/ready
              port: 9000
            initialDelaySeconds: 30
            periodSeconds: 15
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ['ReadWriteOnce']
        storageClassName: standard
        resources:
          requests:
            storage: 100Gi
---
apiVersion: v1
kind: Service
metadata:
  name: minio-headless
  namespace: minio
spec:
  clusterIP: None
  ports:
    - port: 9000
      name: api
    - port: 9001
      name: console
  selector:
    app: minio
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  type: ClusterIP
  ports:
    - port: 9000
      name: api
    - port: 9001
      name: console
  selector:
    app: minio
```

## SDK Examples

### Python (boto3)

```python
# pip install boto3

import boto3
from botocore.client import Config

# Create client
s3 = boto3.client(
    's3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin',
    aws_secret_access_key='minioadmin',
    config=Config(signature_version='s3v4'),
    region_name='us-east-1'
)

# Create bucket
s3.create_bucket(Bucket='my-bucket')

# Upload file
s3.upload_file('local-file.txt', 'my-bucket', 'remote-file.txt')

# Upload with metadata
s3.upload_file(
    'local-file.txt',
    'my-bucket',
    'remote-file.txt',
    ExtraArgs={
        'ContentType': 'text/plain',
        'Metadata': {'author': 'john', 'project': 'demo'}
    }
)

# Upload bytes
s3.put_object(
    Bucket='my-bucket',
    Key='data.json',
    Body=b'{"key": "value"}',
    ContentType='application/json'
)

# Download file
s3.download_file('my-bucket', 'remote-file.txt', 'downloaded.txt')

# Get object
response = s3.get_object(Bucket='my-bucket', Key='data.json')
content = response['Body'].read().decode('utf-8')

# List objects
response = s3.list_objects_v2(Bucket='my-bucket', Prefix='logs/')
for obj in response.get('Contents', []):
    print(f"{obj['Key']} - {obj['Size']} bytes")

# Generate presigned URL
url = s3.generate_presigned_url(
    'get_object',
    Params={'Bucket': 'my-bucket', 'Key': 'remote-file.txt'},
    ExpiresIn=3600  # 1 hour
)
print(f"Presigned URL: {url}")

# Delete object
s3.delete_object(Bucket='my-bucket', Key='remote-file.txt')

# Delete multiple objects
s3.delete_objects(
    Bucket='my-bucket',
    Delete={
        'Objects': [
            {'Key': 'file1.txt'},
            {'Key': 'file2.txt'}
        ]
    }
)
```

### Python (minio-py)

```python
# pip install minio

from minio import Minio
from minio.error import S3Error
from datetime import timedelta
import io

# Create client
client = Minio(
    "localhost:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False  # Set True for HTTPS
)

# Create bucket if not exists
if not client.bucket_exists("my-bucket"):
    client.make_bucket("my-bucket")

# Upload file
client.fput_object(
    "my-bucket",
    "remote-file.txt",
    "local-file.txt",
    content_type="text/plain"
)

# Upload bytes/stream
data = b'Hello, MinIO!'
client.put_object(
    "my-bucket",
    "hello.txt",
    io.BytesIO(data),
    length=len(data),
    content_type="text/plain"
)

# Download file
client.fget_object("my-bucket", "remote-file.txt", "downloaded.txt")

# Get object as stream
response = client.get_object("my-bucket", "hello.txt")
content = response.read().decode('utf-8')
response.close()
response.release_conn()

# List objects
objects = client.list_objects("my-bucket", prefix="logs/", recursive=True)
for obj in objects:
    print(f"{obj.object_name} - {obj.size} bytes")

# Generate presigned URL
url = client.presigned_get_object(
    "my-bucket",
    "remote-file.txt",
    expires=timedelta(hours=1)
)

# Copy object
client.copy_object(
    "dest-bucket",
    "dest-file.txt",
    CopySource("my-bucket", "source-file.txt")
)

# Get object info (stat)
stat = client.stat_object("my-bucket", "remote-file.txt")
print(f"Size: {stat.size}, ETag: {stat.etag}")

# Remove object
client.remove_object("my-bucket", "remote-file.txt")

# Remove multiple objects
from minio.deleteobjects import DeleteObject
delete_list = [DeleteObject("file1.txt"), DeleteObject("file2.txt")]
errors = client.remove_objects("my-bucket", delete_list)
for error in errors:
    print(f"Error: {error}")
```

### Node.js

```javascript
// npm install minio

const Minio = require('minio');
const fs = require('fs');

// Create client
const minioClient = new Minio.Client({
  endPoint: 'localhost',
  port: 9000,
  useSSL: false,
  accessKey: 'minioadmin',
  secretKey: 'minioadmin',
});

// Create bucket
async function createBucket() {
  const exists = await minioClient.bucketExists('my-bucket');
  if (!exists) {
    await minioClient.makeBucket('my-bucket', 'us-east-1');
    console.log('Bucket created');
  }
}

// Upload file
async function uploadFile() {
  const metaData = {
    'Content-Type': 'text/plain',
    'X-Amz-Meta-Author': 'john',
  };

  await minioClient.fPutObject(
    'my-bucket',
    'remote-file.txt',
    'local-file.txt',
    metaData,
  );
  console.log('File uploaded');
}

// Upload buffer
async function uploadBuffer() {
  const buffer = Buffer.from('Hello, MinIO!');
  await minioClient.putObject('my-bucket', 'hello.txt', buffer);
}

// Download file
async function downloadFile() {
  await minioClient.fGetObject(
    'my-bucket',
    'remote-file.txt',
    'downloaded.txt',
  );
}

// Get object as stream
async function getObjectStream() {
  const stream = await minioClient.getObject('my-bucket', 'hello.txt');
  let data = '';
  stream.on('data', chunk => (data += chunk));
  stream.on('end', () => console.log(data));
}

// List objects
async function listObjects() {
  const stream = minioClient.listObjects('my-bucket', 'logs/', true);
  stream.on('data', obj => console.log(obj.name, obj.size));
  stream.on('error', err => console.error(err));
}

// Presigned URL
async function getPresignedUrl() {
  const url = await minioClient.presignedGetObject(
    'my-bucket',
    'remote-file.txt',
    3600, // expires in 1 hour
  );
  console.log('Presigned URL:', url);
}

// Presigned PUT URL (for uploads)
async function getPresignedPutUrl() {
  const url = await minioClient.presignedPutObject(
    'my-bucket',
    'upload-target.txt',
    3600,
  );
  console.log('Upload URL:', url);
}

// Delete object
async function deleteObject() {
  await minioClient.removeObject('my-bucket', 'remote-file.txt');
}

// Run examples
(async () => {
  try {
    await createBucket();
    await uploadFile();
    await listObjects();
  } catch (err) {
    console.error(err);
  }
})();
```

### Go

```go
// go get github.com/minio/minio-go/v7

package main

import (
    "context"
    "fmt"
    "log"
    "strings"
    "time"

    "github.com/minio/minio-go/v7"
    "github.com/minio/minio-go/v7/pkg/credentials"
)

func main() {
    ctx := context.Background()

    // Create client
    client, err := minio.New("localhost:9000", &minio.Options{
        Creds:  credentials.NewStaticV4("minioadmin", "minioadmin", ""),
        Secure: false,
    })
    if err != nil {
        log.Fatal(err)
    }

    bucketName := "my-bucket"

    // Create bucket
    exists, err := client.BucketExists(ctx, bucketName)
    if err != nil {
        log.Fatal(err)
    }
    if !exists {
        err = client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{
            Region: "us-east-1",
        })
        if err != nil {
            log.Fatal(err)
        }
    }

    // Upload file
    _, err = client.FPutObject(ctx, bucketName, "remote-file.txt", "local-file.txt",
        minio.PutObjectOptions{ContentType: "text/plain"})
    if err != nil {
        log.Fatal(err)
    }

    // Upload from reader
    content := "Hello, MinIO!"
    _, err = client.PutObject(ctx, bucketName, "hello.txt",
        strings.NewReader(content), int64(len(content)),
        minio.PutObjectOptions{ContentType: "text/plain"})
    if err != nil {
        log.Fatal(err)
    }

    // Download file
    err = client.FGetObject(ctx, bucketName, "remote-file.txt", "downloaded.txt",
        minio.GetObjectOptions{})
    if err != nil {
        log.Fatal(err)
    }

    // Get object
    obj, err := client.GetObject(ctx, bucketName, "hello.txt", minio.GetObjectOptions{})
    if err != nil {
        log.Fatal(err)
    }
    defer obj.Close()

    // List objects
    objectCh := client.ListObjects(ctx, bucketName, minio.ListObjectsOptions{
        Prefix:    "logs/",
        Recursive: true,
    })
    for object := range objectCh {
        if object.Err != nil {
            log.Println(object.Err)
            continue
        }
        fmt.Printf("%s - %d bytes\n", object.Key, object.Size)
    }

    // Presigned URL
    presignedURL, err := client.PresignedGetObject(ctx, bucketName, "remote-file.txt",
        time.Hour, nil)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println("Presigned URL:", presignedURL)

    // Delete object
    err = client.RemoveObject(ctx, bucketName, "remote-file.txt",
        minio.RemoveObjectOptions{})
    if err != nil {
        log.Fatal(err)
    }
}
```

## Backstage Integration

### TechDocs Configuration

```yaml
# app-config.yaml
techdocs:
  builder: 'local'
  generator:
    runIn: 'docker'
  publisher:
    type: 'awsS3'
    awsS3:
      bucketName: 'techdocs'
      region: 'us-east-1'
      endpoint: 'http://minio:9000'
      s3ForcePathStyle: true
      credentials:
        accessKeyId: ${MINIO_ACCESS_KEY}
        secretAccessKey: ${MINIO_SECRET_KEY}
```

### Environment Variables

```bash
# .env
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_ENDPOINT=http://minio:9000
```

## mc CLI Reference

```bash
# Configure alias
mc alias set myminio http://localhost:9000 minioadmin minioadmin

# Bucket operations
mc mb myminio/bucket                  # Create bucket
mc rb myminio/bucket                  # Remove bucket (must be empty)
mc rb --force myminio/bucket          # Force remove with contents
mc ls myminio                         # List buckets
mc ls myminio/bucket                  # List objects

# Object operations
mc cp file.txt myminio/bucket/        # Upload
mc cp myminio/bucket/file.txt ./      # Download
mc cp -r ./dir myminio/bucket/        # Upload directory
mc cat myminio/bucket/file.txt        # View content
mc head myminio/bucket/file.txt       # View first 10 lines
mc rm myminio/bucket/file.txt         # Delete
mc rm -r myminio/bucket/prefix/       # Delete recursively

# Sync
mc mirror ./local myminio/bucket      # Sync local to remote
mc mirror myminio/bucket ./local      # Sync remote to local
mc mirror --watch ./local myminio/bucket  # Continuous sync

# Find objects
mc find myminio/bucket --name "*.log"
mc find myminio/bucket --older-than 30d
mc find myminio/bucket --larger 10MB

# Object info
mc stat myminio/bucket/file.txt

# Presigned URLs
mc share download myminio/bucket/file.txt
mc share upload myminio/bucket/

# Admin commands
mc admin info myminio
mc admin user list myminio
mc admin policy list myminio
```

## Troubleshooting

### Common Issues

| Issue                 | Cause                   | Solution                         |
| --------------------- | ----------------------- | -------------------------------- |
| Connection refused    | MinIO not running       | Check container/pod status       |
| Access Denied         | Invalid credentials     | Verify access key and secret     |
| Bucket not found      | Bucket doesn't exist    | Create bucket first with `mc mb` |
| SSL certificate error | Self-signed cert        | Add `--insecure` flag or add CA  |
| Slow uploads          | Network bottleneck      | Check bandwidth, use multipart   |
| Disk full             | Storage exhausted       | Add drives or clean old data     |
| Healing in progress   | Recent drive failure    | Wait for healing to complete     |
| No quorum             | Too many drives offline | Restore drives, check hardware   |

### Diagnostic Commands

```bash
# Check server status
mc admin info myminio

# Health check
curl http://localhost:9000/minio/health/live
curl http://localhost:9000/minio/health/ready
curl http://localhost:9000/minio/health/cluster

# View logs
mc admin logs myminio
mc admin logs myminio --type minio
mc admin logs myminio --type application

# Trace requests
mc admin trace myminio -a

# Check disk usage
mc admin du myminio/bucket

# Scanner/healing status
mc admin scanner status myminio
mc admin heal myminio --dry-run

# Profile performance
mc admin profile start myminio --type cpu
mc admin profile stop myminio
```

### Recovery Procedures

```bash
# Heal specific bucket
mc admin heal myminio/bucket --recursive

# Force heal (ignore errors)
mc admin heal myminio --recursive --remove

# Replace failed drive
# 1. Stop MinIO on affected node
# 2. Replace physical drive
# 3. Format new drive (XFS)
# 4. Mount at same path
# 5. Start MinIO
# 6. Healing starts automatically

# Decommission node
mc admin decommission start myminio http://node4/data
mc admin decommission status myminio
```

## Best Practices

### Design Guidelines

1. **Use erasure coding** - Don't use RAID; MinIO's EC provides better protection
2. **Use dedicated drives** - One drive per mount point, XFS filesystem
3. **Plan for growth** - Add server pools, not individual drives
4. **Use object locking for compliance** - WORM mode for regulatory data
5. **Enable versioning** - Protect against accidental deletes
6. **Use lifecycle policies** - Automate data management

### Security Checklist

- [ ] Change default root credentials
- [ ] Enable TLS for all connections
- [ ] Use IAM policies with least privilege
- [ ] Enable audit logging
- [ ] Configure encryption (SSE-S3 or SSE-KMS)
- [ ] Set up bucket policies
- [ ] Enable object locking for sensitive data
- [ ] Use presigned URLs for temporary access
- [ ] Configure network policies/firewall

### Performance Checklist

- [ ] Use XFS filesystem with noatime
- [ ] Ensure adequate network bandwidth
- [ ] Use multipart uploads for large files
- [ ] Enable client-side compression
- [ ] Configure appropriate erasure coding
- [ ] Monitor disk latency
- [ ] Use caching for read-heavy workloads

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and configuration details
