#!/usr/bin/env python3
"""
Create catalog-info.yaml files for each entity with TechDocs enabled.
"""

from pathlib import Path

CATALOG_DIR = Path("/Users/ayodeleajayi/Workspace/backstage/catalog")

# Entity definitions with full metadata
ENTITIES = {
    # cloud-components.yaml - Components
    "aws-services": {
        "kind": "Component",
        "title": "AWS Services Integration",
        "desc": "AWS cloud services and infrastructure management",
        "type": "service",
        "lifecycle": "production",
        "owner": "cloud-team",
        "system": "cloud-services-platform",
        "tags": ["aws", "cloud", "ec2", "s3", "rds", "lambda"],
        "providesApis": ["aws-api"],
    },
    "azure-services": {
        "kind": "Component",
        "title": "Azure Services Integration",
        "desc": "Microsoft Azure cloud services and resources",
        "type": "service",
        "lifecycle": "production",
        "owner": "cloud-team",
        "system": "cloud-services-platform",
        "tags": ["azure", "cloud", "vm", "storage"],
        "providesApis": ["azure-api"],
    },
    "gcp-services": {
        "kind": "Component",
        "title": "Google Cloud Platform Services",
        "desc": "GCP cloud services and infrastructure",
        "type": "service",
        "lifecycle": "production",
        "owner": "cloud-team",
        "system": "cloud-services-platform",
        "tags": ["gcp", "cloud", "compute-engine"],
        "providesApis": ["gcp-api"],
    },
    "multi-cloud-management": {
        "kind": "Component",
        "title": "Multi-Cloud Management",
        "desc": "Unified management across AWS, Azure, and GCP",
        "type": "service",
        "lifecycle": "production",
        "owner": "cloud-team",
        "system": "cloud-services-platform",
        "tags": ["multi-cloud", "management"],
    },
    
    # sample-components.yaml
    "ansible-webserver": {
        "kind": "Component",
        "title": "Webserver Playbook",
        "desc": "Ansible playbook for configuring Nginx/Apache web servers",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "awx-automation-platform",
        "tags": ["ansible", "webserver", "nginx"],
    },
    "ansible-docker-host": {
        "kind": "Component",
        "title": "Docker Host Playbook",
        "desc": "Ansible playbook for setting up Docker on Linux hosts",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "awx-automation-platform",
        "tags": ["ansible", "docker"],
    },
    "sample-nodejs-api": {
        "kind": "Component",
        "title": "Node.js REST API",
        "desc": "Sample Node.js Express API with PostgreSQL",
        "type": "service",
        "lifecycle": "experimental",
        "owner": "platform-team",
        "tags": ["nodejs", "api", "express"],
    },
    "sample-react-frontend": {
        "kind": "Component",
        "title": "React Frontend App",
        "desc": "Sample React frontend with Material-UI",
        "type": "website",
        "lifecycle": "experimental",
        "owner": "platform-team",
        "tags": ["react", "frontend"],
    },
    
    # infrastructure-components.yaml
    "cloudformation-templates": {
        "kind": "Component",
        "title": "CloudFormation Templates",
        "desc": "AWS CloudFormation templates for infrastructure deployment",
        "type": "library",
        "lifecycle": "production",
        "owner": "cloud-team",
        "system": "infrastructure-as-code-platform",
        "tags": ["cloudformation", "aws", "iac"],
    },
    "pulumi-projects": {
        "kind": "Component",
        "title": "Pulumi Infrastructure Projects",
        "desc": "Pulumi infrastructure as code projects",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "infrastructure-as-code-platform",
        "tags": ["pulumi", "iac"],
    },
    "helm-charts": {
        "kind": "Component",
        "title": "Helm Charts Repository",
        "desc": "Kubernetes Helm charts for application deployment",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "kubernetes-operators",
        "tags": ["helm", "kubernetes"],
    },
    "docker-images": {
        "kind": "Component",
        "title": "Docker Images Registry",
        "desc": "Company Docker images and base images",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "infrastructure-as-code-platform",
        "tags": ["docker", "containers"],
    },
    "packer": {
        "kind": "Component",
        "title": "Packer Image Builder",
        "desc": "HashiCorp Packer for building machine images",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "infrastructure-as-code-platform",
        "tags": ["packer", "images"],
    },
    
    # observability-components.yaml
    "prometheus-stack": {
        "kind": "Component",
        "title": "Prometheus Monitoring Stack",
        "desc": "Prometheus, Grafana, and AlertManager for metrics and monitoring",
        "type": "service",
        "lifecycle": "production",
        "owner": "sre-team",
        "system": "observability-platform",
        "tags": ["prometheus", "grafana", "monitoring"],
        "providesApis": ["prometheus-api", "grafana-api"],
    },
    "elk-stack": {
        "kind": "Component",
        "title": "ELK Stack",
        "desc": "Centralized logging with Elasticsearch, Logstash, Kibana",
        "type": "service",
        "lifecycle": "production",
        "owner": "sre-team",
        "system": "observability-platform",
        "tags": ["elasticsearch", "logstash", "kibana", "logging"],
        "providesApis": ["elasticsearch-api", "kibana-api"],
    },
    "jaeger-tracing": {
        "kind": "Component",
        "title": "Jaeger Distributed Tracing",
        "desc": "Distributed tracing and performance monitoring",
        "type": "service",
        "lifecycle": "production",
        "owner": "sre-team",
        "system": "observability-platform",
        "tags": ["jaeger", "tracing"],
        "providesApis": ["jaeger-api"],
    },
    "datadog-integration": {
        "kind": "Component",
        "title": "Datadog Monitoring Integration",
        "desc": "Datadog APM, infrastructure monitoring, and log management",
        "type": "service",
        "lifecycle": "production",
        "owner": "sre-team",
        "system": "observability-platform",
        "tags": ["datadog", "apm", "monitoring"],
        "providesApis": ["datadog-api"],
    },
    "new-relic-integration": {
        "kind": "Component",
        "title": "New Relic Monitoring",
        "desc": "Application performance monitoring and observability",
        "type": "service",
        "lifecycle": "production",
        "owner": "sre-team",
        "system": "observability-platform",
        "tags": ["new-relic", "apm"],
        "providesApis": ["newrelic-api"],
    },
    "splunk-enterprise": {
        "kind": "Component",
        "title": "Splunk Enterprise",
        "desc": "Machine data analytics and security monitoring",
        "type": "service",
        "lifecycle": "production",
        "owner": "security-team",
        "system": "observability-platform",
        "tags": ["splunk", "analytics", "siem"],
        "providesApis": ["splunk-api"],
    },
    "pagerduty-integration": {
        "kind": "Component",
        "title": "PagerDuty Incident Management",
        "desc": "Incident response and on-call management",
        "type": "service",
        "lifecycle": "production",
        "owner": "sre-team",
        "system": "observability-platform",
        "tags": ["pagerduty", "incident-management"],
        "providesApis": ["pagerduty-api"],
    },
    
    # testing-components.yaml
    "testing-frameworks": {
        "kind": "Component",
        "title": "Testing Frameworks Suite",
        "desc": "Comprehensive testing frameworks for unit, integration, and e2e testing",
        "type": "library",
        "lifecycle": "production",
        "owner": "quality-team",
        "system": "testing-automation-platform",
        "tags": ["testing", "jest", "cypress"],
        "providesApis": ["testing-api"],
    },
    "sonarqube": {
        "kind": "Component",
        "title": "SonarQube Code Quality",
        "desc": "Static code analysis and quality gate enforcement",
        "type": "service",
        "lifecycle": "production",
        "owner": "quality-team",
        "system": "testing-automation-platform",
        "tags": ["code-quality", "static-analysis"],
    },
    "security-scanning-suite": {
        "kind": "Component",
        "title": "Security Scanning Suite",
        "desc": "Vulnerability scanning, SAST, DAST, and dependency analysis",
        "type": "service",
        "lifecycle": "production",
        "owner": "security-team",
        "system": "security-compliance-platform",
        "tags": ["security", "vulnerability-scanning"],
        "providesApis": ["security-api"],
    },
    "performance-testing": {
        "kind": "Component",
        "title": "Performance Testing Suite",
        "desc": "Load testing, stress testing, and performance monitoring",
        "type": "library",
        "lifecycle": "production",
        "owner": "quality-team",
        "system": "testing-automation-platform",
        "tags": ["performance-testing", "load-testing"],
    },
    "ci-cd-pipelines": {
        "kind": "Component",
        "title": "CI/CD Pipeline Templates",
        "desc": "Standardized CI/CD pipeline templates for various technologies",
        "type": "library",
        "lifecycle": "production",
        "owner": "devops-team",
        "system": "ci-cd-platform",
        "tags": ["ci-cd", "jenkins", "github-actions"],
        "providesApis": ["pipeline-api"],
    },
    "artifact-repository": {
        "kind": "Component",
        "title": "Artifact Repository",
        "desc": "Maven, npm, Docker, and generic artifact storage",
        "type": "service",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "ci-cd-platform",
        "tags": ["artifacts", "maven", "npm"],
    },
    
    # data-components.yaml
    "postgresql-cluster": {
        "kind": "Component",
        "title": "PostgreSQL Cluster",
        "desc": "PostgreSQL database cluster configuration",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["postgresql", "database"],
        "providesApis": ["postgresql-api"],
    },
    "mongodb-cluster": {
        "kind": "Component",
        "title": "MongoDB Cluster",
        "desc": "MongoDB database cluster configuration",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["mongodb", "database", "nosql"],
        "providesApis": ["mongodb-api"],
    },
    "redis-cluster": {
        "kind": "Component",
        "title": "Redis Cluster",
        "desc": "Redis in-memory data store cluster",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["redis", "cache"],
        "providesApis": ["redis-api"],
    },
    "elasticsearch-data": {
        "kind": "Component",
        "title": "Elasticsearch Data",
        "desc": "Elasticsearch search and analytics engine",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["elasticsearch", "search"],
        "providesApis": ["elasticsearch-data-api"],
    },
    "apache-kafka": {
        "kind": "Component",
        "title": "Apache Kafka",
        "desc": "Distributed event streaming platform",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["kafka", "streaming"],
        "providesApis": ["kafka-api"],
    },
    "rabbitmq-cluster": {
        "kind": "Component",
        "title": "RabbitMQ Cluster",
        "desc": "Message broker for distributed systems",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["rabbitmq", "messaging"],
        "providesApis": ["rabbitmq-api"],
    },
    "apache-spark": {
        "kind": "Component",
        "title": "Apache Spark",
        "desc": "Unified analytics engine for big data",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["spark", "big-data"],
        "providesApis": ["spark-api"],
    },
    "apache-airflow": {
        "kind": "Component",
        "title": "Apache Airflow",
        "desc": "Workflow orchestration platform",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["airflow", "workflow"],
        "providesApis": ["airflow-api"],
    },
    "zookeeper-ensemble": {
        "kind": "Component",
        "title": "ZooKeeper Ensemble",
        "desc": "Distributed coordination service",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["zookeeper", "coordination"],
    },
    "minio-storage": {
        "kind": "Component",
        "title": "MinIO Storage",
        "desc": "High-performance object storage",
        "type": "service",
        "lifecycle": "production",
        "owner": "data-team",
        "system": "data-services-platform",
        "tags": ["minio", "object-storage", "s3"],
        "providesApis": ["s3-api"],
    },
    
    # awx components
    "awx-core": {
        "kind": "Component",
        "title": "AWX Core",
        "desc": "AWX automation controller core components",
        "type": "service",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "awx-automation-platform",
        "tags": ["awx", "ansible", "automation"],
        "providesApis": ["awx-rest-api", "awx-websocket-api"],
    },
    "awx-operator": {
        "kind": "Component",
        "title": "AWX Operator",
        "desc": "Kubernetes operator for AWX deployment",
        "type": "service",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "awx-automation-platform",
        "tags": ["awx", "kubernetes", "operator"],
        "providesApis": ["awx-operator-api"],
    },
    "awx-helm-chart": {
        "kind": "Component",
        "title": "AWX Helm Chart",
        "desc": "Helm chart for AWX deployment",
        "type": "library",
        "lifecycle": "production",
        "owner": "platform-team",
        "system": "awx-automation-platform",
        "tags": ["awx", "helm", "kubernetes"],
    },
}

def create_catalog_info(name, info):
    """Create catalog-info.yaml for an entity."""
    entity_dir = CATALOG_DIR / name
    
    tags_str = "\n".join([f"    - {tag}" for tag in info.get("tags", [])])
    
    provides_apis = info.get("providesApis", [])
    provides_apis_str = ""
    if provides_apis:
        apis = "\n".join([f"    - {api}" for api in provides_apis])
        provides_apis_str = f"\n  providesApis:\n{apis}"
    
    system_str = ""
    if info.get("system"):
        system_str = f"\n  system: {info['system']}"
    
    content = f"""apiVersion: backstage.io/v1alpha1
kind: {info['kind']}
metadata:
  name: {name}
  title: {info['title']}
  description: {info['desc']}
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
{tags_str}
spec:
  type: {info['type']}
  lifecycle: {info['lifecycle']}
  owner: {info['owner']}{system_str}{provides_apis_str}
"""
    
    with open(entity_dir / "catalog-info.yaml", "w") as f:
        f.write(content)
    
    print(f"Created catalog-info.yaml for: {name}")

def main():
    print("Creating catalog-info.yaml files...")
    
    for name, info in ENTITIES.items():
        create_catalog_info(name, info)
    
    print(f"\nCreated catalog-info.yaml for {len(ENTITIES)} entities")

if __name__ == "__main__":
    main()
