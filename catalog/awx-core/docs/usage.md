# Usage Guide

## Docker Compose Deployment (Development)

```yaml
# docker-compose.yaml
version: '3.8'

services:
  awx-web:
    image: quay.io/ansible/awx:24.0.0
    container_name: awx-web
    depends_on:
      - postgres
      - redis
    ports:
      - "8080:8052"
    volumes:
      - awx-projects:/var/lib/awx/projects
    environment:
      DATABASE_HOST: postgres
      DATABASE_NAME: awx
      DATABASE_USER: awx
      DATABASE_PASSWORD: awxpassword
      DATABASE_PORT: 5432
      AWX_ADMIN_USER: admin
      AWX_ADMIN_PASSWORD: password
      SECRET_KEY: supersecretkey
    command: /usr/bin/launch_awx.sh
    networks:
      - awx-net

  awx-task:
    image: quay.io/ansible/awx:24.0.0
    container_name: awx-task
    depends_on:
      - awx-web
    volumes:
      - awx-projects:/var/lib/awx/projects
    environment:
      DATABASE_HOST: postgres
      DATABASE_NAME: awx
      DATABASE_USER: awx
      DATABASE_PASSWORD: awxpassword
      DATABASE_PORT: 5432
      SECRET_KEY: supersecretkey
      SUPERVISOR_WEB_CONFIG_PATH: /etc/tower/conf.d/supervisor-task.conf
    command: /usr/bin/launch_awx_task.sh
    networks:
      - awx-net

  postgres:
    image: postgres:15-alpine
    container_name: awx-postgres
    environment:
      POSTGRES_DB: awx
      POSTGRES_USER: awx
      POSTGRES_PASSWORD: awxpassword
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - awx-net

  redis:
    image: redis:7-alpine
    container_name: awx-redis
    networks:
      - awx-net

volumes:
  awx-projects:
  postgres-data:

networks:
  awx-net:
    driver: bridge
```

## Kubernetes Deployment

### AWX Operator Installation

```bash
# Install AWX Operator
kubectl apply -k github.com/ansible/awx-operator/config/default?ref=2.12.0

# Wait for operator
kubectl wait --for=condition=available deployment/awx-operator-controller-manager -n awx --timeout=300s

# Create AWX instance
kubectl apply -f awx-instance.yaml
```

### Complete AWX Instance

```yaml
# awx-instance.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
  
  # Ingress configuration
  ingress_type: ingress
  hostname: awx.example.com
  ingress_annotations: |
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  ingress_tls_secret: awx-tls
  
  # Admin credentials
  admin_user: admin
  admin_password_secret: awx-admin-password
  
  # Resource configuration
  web_replicas: 2
  task_replicas: 2
  
  web_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 4000m
      memory: 8Gi
  
  # PostgreSQL
  postgres_storage_class: standard
  postgres_storage_requirements:
    requests:
      storage: 20Gi
  
  # Projects
  projects_persistence: true
  projects_storage_class: standard
  projects_storage_size: 10Gi
  
  # Image pull
  image_pull_secrets:
    - name: registry-secret
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-admin-password
  namespace: awx
type: Opaque
stringData:
  password: "YourSecurePassword123!"
```

## API Examples

### Authentication

```bash
# Get OAuth2 token
TOKEN=$(curl -s -X POST \
  "https://awx.example.com/api/v2/tokens/" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{"description": "API Token", "scope": "write"}' | jq -r '.token')

# Use token in requests
curl -H "Authorization: Bearer $TOKEN" \
  "https://awx.example.com/api/v2/me/"
```

### Create Resources

```bash
# Create Organization
curl -X POST "https://awx.example.com/api/v2/organizations/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production",
    "description": "Production automation"
  }'

# Create Project (Git)
curl -X POST "https://awx.example.com/api/v2/projects/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ansible Playbooks",
    "organization": 1,
    "scm_type": "git",
    "scm_url": "https://github.com/org/ansible-playbooks.git",
    "scm_branch": "main",
    "credential": 2,
    "scm_update_on_launch": true
  }'

# Create Inventory
curl -X POST "https://awx.example.com/api/v2/inventories/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Servers",
    "organization": 1,
    "variables": "---\nansible_user: ansible"
  }'

# Add Host to Inventory
curl -X POST "https://awx.example.com/api/v2/hosts/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server-01",
    "inventory": 1,
    "variables": "---\nansible_host: 192.168.1.10"
  }'

# Create Machine Credential
curl -X POST "https://awx.example.com/api/v2/credentials/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "SSH Key",
    "organization": 1,
    "credential_type": 1,
    "inputs": {
      "username": "ansible",
      "ssh_key_data": "-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----"
    }
  }'

# Create Job Template
curl -X POST "https://awx.example.com/api/v2/job_templates/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Deploy Application",
    "job_type": "run",
    "inventory": 1,
    "project": 1,
    "playbook": "deploy.yml",
    "credentials": [1],
    "execution_environment": 1,
    "limit": "",
    "extra_vars": "---\nversion: \"1.0.0\"",
    "ask_variables_on_launch": true
  }'
```

### Launch and Monitor Jobs

```bash
# Launch Job Template
JOB_ID=$(curl -s -X POST \
  "https://awx.example.com/api/v2/job_templates/1/launch/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"version": "2.0.0"}}' | jq -r '.id')

echo "Launched job: $JOB_ID"

# Monitor Job Status
while true; do
  STATUS=$(curl -s \
    "https://awx.example.com/api/v2/jobs/$JOB_ID/" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.status')
  
  echo "Job status: $STATUS"
  
  if [[ "$STATUS" == "successful" || "$STATUS" == "failed" || "$STATUS" == "canceled" ]]; then
    break
  fi
  
  sleep 5
done

# Get Job Output
curl "https://awx.example.com/api/v2/jobs/$JOB_ID/stdout/?format=txt" \
  -H "Authorization: Bearer $TOKEN"
```

### AWX CLI (awxkit)

```bash
# Install AWX CLI
pip install awxkit

# Configure
export TOWER_HOST=https://awx.example.com
export TOWER_USERNAME=admin
export TOWER_PASSWORD=password

# List resources
awx organizations list
awx projects list
awx inventories list
awx job_templates list

# Launch job template
awx job_templates launch "Deploy Application" \
  --extra_vars '{"version": "2.0.0"}' \
  --monitor

# Create inventory from file
awx inventory_source create \
  --name "AWS EC2" \
  --inventory "Production" \
  --source "ec2" \
  --credential "AWS Credentials"

# Export resources
awx export --organization "Production" > awx-export.json

# Import resources
awx import < awx-export.json
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yaml
name: Deploy via AWX

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger AWX Job
        uses: ansible/awx-action@v1
        with:
          awx_url: ${{ secrets.AWX_URL }}
          awx_token: ${{ secrets.AWX_TOKEN }}
          job_template_id: 10
          extra_vars: |
            environment: ${{ github.event.inputs.environment || 'staging' }}
            version: ${{ github.sha }}
          wait: true
          timeout: 600

      - name: Get Job Results
        if: always()
        run: |
          curl -s -H "Authorization: Bearer ${{ secrets.AWX_TOKEN }}" \
            "${{ secrets.AWX_URL }}/api/v2/jobs/${{ steps.awx.outputs.job_id }}/" | jq .
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy

variables:
  AWX_URL: https://awx.example.com
  JOB_TEMPLATE_ID: "10"

deploy:
  stage: deploy
  image: python:3.11
  script:
    - pip install awxkit
    - |
      awx job_templates launch $JOB_TEMPLATE_ID \
        --extra_vars "{\"version\": \"$CI_COMMIT_SHA\", \"environment\": \"$CI_ENVIRONMENT_NAME\"}" \
        --monitor \
        --timeout 600
  environment:
    name: $CI_ENVIRONMENT_NAME
  only:
    - main
  variables:
    TOWER_HOST: $AWX_URL
    TOWER_OAUTH_TOKEN: $AWX_TOKEN
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        AWX_HOST = 'https://awx.example.com'
        AWX_TOKEN = credentials('awx-token')
    }
    
    stages {
        stage('Deploy via AWX') {
            steps {
                script {
                    def response = httpRequest(
                        url: "${AWX_HOST}/api/v2/job_templates/10/launch/",
                        httpMode: 'POST',
                        customHeaders: [[name: 'Authorization', value: "Bearer ${AWX_TOKEN}"]],
                        contentType: 'APPLICATION_JSON',
                        requestBody: """
                            {
                                "extra_vars": {
                                    "version": "${env.BUILD_NUMBER}",
                                    "environment": "staging"
                                }
                            }
                        """
                    )
                    
                    def job = readJSON text: response.content
                    def jobId = job.id
                    
                    // Wait for job completion
                    timeout(time: 30, unit: 'MINUTES') {
                        waitUntil {
                            def statusResponse = httpRequest(
                                url: "${AWX_HOST}/api/v2/jobs/${jobId}/",
                                customHeaders: [[name: 'Authorization', value: "Bearer ${AWX_TOKEN}"]]
                            )
                            def status = readJSON(text: statusResponse.content).status
                            
                            if (status == 'failed') {
                                error "AWX job failed"
                            }
                            
                            return status == 'successful'
                        }
                    }
                }
            }
        }
    }
}
```

## Python SDK Examples

```python
# awx_client.py
import requests
from typing import Dict, Any, Optional
import time

class AWXClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        })
    
    def _request(self, method: str, endpoint: str, **kwargs) -> Dict:
        url = f"{self.base_url}/api/v2/{endpoint.lstrip('/')}"
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response.json() if response.content else {}
    
    def get(self, endpoint: str) -> Dict:
        return self._request('GET', endpoint)
    
    def post(self, endpoint: str, data: Dict) -> Dict:
        return self._request('POST', endpoint, json=data)
    
    def launch_job_template(
        self,
        template_id: int,
        extra_vars: Optional[Dict] = None,
        inventory: Optional[int] = None,
        limit: Optional[str] = None,
        wait: bool = True,
        timeout: int = 600
    ) -> Dict:
        """Launch a job template and optionally wait for completion."""
        payload = {}
        if extra_vars:
            payload['extra_vars'] = extra_vars
        if inventory:
            payload['inventory'] = inventory
        if limit:
            payload['limit'] = limit
        
        job = self.post(f'job_templates/{template_id}/launch/', payload)
        
        if wait:
            return self.wait_for_job(job['id'], timeout)
        return job
    
    def wait_for_job(self, job_id: int, timeout: int = 600) -> Dict:
        """Wait for job to complete."""
        start_time = time.time()
        
        while True:
            job = self.get(f'jobs/{job_id}/')
            status = job['status']
            
            if status in ['successful', 'failed', 'canceled', 'error']:
                return job
            
            if time.time() - start_time > timeout:
                raise TimeoutError(f"Job {job_id} did not complete within {timeout}s")
            
            time.sleep(5)
    
    def get_job_output(self, job_id: int) -> str:
        """Get job stdout."""
        response = self.session.get(
            f"{self.base_url}/api/v2/jobs/{job_id}/stdout/",
            params={'format': 'txt'}
        )
        return response.text


# Usage
if __name__ == '__main__':
    client = AWXClient(
        base_url='https://awx.example.com',
        token='your-token'
    )
    
    # Launch deployment
    result = client.launch_job_template(
        template_id=10,
        extra_vars={'version': '2.0.0', 'environment': 'staging'},
        wait=True,
        timeout=900
    )
    
    print(f"Job Status: {result['status']}")
    
    if result['status'] == 'failed':
        print(client.get_job_output(result['id']))
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Job stays pending | No capacity available | Check instance capacity, scale task pods |
| Project sync fails | Git credentials invalid | Verify SCM credentials |
| Inventory sync fails | Cloud credentials/permissions | Check credential permissions |
| Jobs failing immediately | Execution environment issue | Verify EE image, check dependencies |
| Database connection errors | PostgreSQL overloaded | Scale database, check connections |
| Slow UI | High job volume | Enable Redis caching, scale web pods |
| WebSocket disconnects | Nginx timeout | Increase proxy_read_timeout |
| Credential decryption fails | SECRET_KEY changed | Restore original SECRET_KEY |

### Debug Commands

```bash
# Check AWX pods
kubectl get pods -n awx

# View AWX logs
kubectl logs -f deployment/awx-web -n awx
kubectl logs -f deployment/awx-task -n awx

# Check database
kubectl exec -it deployment/awx-postgres -n awx -- psql -U awx -c "SELECT * FROM main_instance;"

# Check receptor status
kubectl exec -it deployment/awx-task -n awx -- receptorctl status

# API debug
curl -v -H "Authorization: Bearer $TOKEN" \
  "https://awx.example.com/api/v2/ping/"
```

## Best Practices

1. **Use Execution Environments** - Containerize dependencies for reproducibility
2. **Enable SCM update on launch** - Keep playbooks in sync
3. **Use credential types** - Never hardcode secrets
4. **Implement RBAC** - Least privilege access
5. **Monitor capacity** - Scale before saturation
6. **Use workflow templates** - Orchestrate complex deployments
7. **Enable notifications** - Alert on failures
8. **Regular backups** - Database and SECRET_KEY
9. **Use limit patterns** - Avoid full inventory runs
10. **Tag everything** - Labels for organization
