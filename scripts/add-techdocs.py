#!/usr/bin/env python3
"""
Add TechDocs to all Components and APIs in the catalog.
Creates mkdocs.yml and docs/index.md for each entity.
"""

import os
from pathlib import Path

CATALOG_DIR = Path("/Users/ayodeleajayi/Workspace/backstage/catalog")

# Entities that need TechDocs
ENTITIES = {
    # cloud-components.yaml
    "aws-services": {"title": "AWS Services Integration", "desc": "AWS cloud services and infrastructure management", "category": "cloud"},
    "azure-services": {"title": "Azure Services Integration", "desc": "Microsoft Azure cloud services and resources", "category": "cloud"},
    "gcp-services": {"title": "Google Cloud Platform Services", "desc": "GCP cloud services and infrastructure", "category": "cloud"},
    "multi-cloud-management": {"title": "Multi-Cloud Management", "desc": "Unified management across AWS, Azure, and GCP", "category": "cloud"},
    
    # sample-components.yaml
    "ansible-webserver": {"title": "Webserver Playbook", "desc": "Ansible playbook for configuring Nginx/Apache web servers", "category": "ansible"},
    "ansible-docker-host": {"title": "Docker Host Playbook", "desc": "Ansible playbook for setting up Docker on Linux hosts", "category": "ansible"},
    "sample-nodejs-api": {"title": "Node.js REST API", "desc": "Sample Node.js Express API with PostgreSQL", "category": "samples"},
    "sample-react-frontend": {"title": "React Frontend App", "desc": "Sample React frontend with Material-UI", "category": "samples"},
    
    # infrastructure-components.yaml
    "cloudformation-templates": {"title": "CloudFormation Templates", "desc": "AWS CloudFormation templates for infrastructure deployment", "category": "infrastructure"},
    "pulumi-projects": {"title": "Pulumi Infrastructure Projects", "desc": "Pulumi infrastructure as code projects", "category": "infrastructure"},
    "helm-charts": {"title": "Helm Charts Repository", "desc": "Kubernetes Helm charts for application deployment", "category": "infrastructure"},
    "docker-images": {"title": "Docker Images Registry", "desc": "Company Docker images and base images", "category": "infrastructure"},
    "packer": {"title": "Packer Image Builder", "desc": "HashiCorp Packer for building machine images", "category": "infrastructure"},
    
    # observability-components.yaml
    "prometheus-stack": {"title": "Prometheus Monitoring Stack", "desc": "Prometheus, Grafana, and AlertManager for metrics and monitoring", "category": "observability"},
    "elk-stack": {"title": "ELK Stack", "desc": "Centralized logging with Elasticsearch, Logstash, Kibana", "category": "observability"},
    "jaeger-tracing": {"title": "Jaeger Distributed Tracing", "desc": "Distributed tracing and performance monitoring", "category": "observability"},
    "datadog-integration": {"title": "Datadog Monitoring Integration", "desc": "Datadog APM, infrastructure monitoring, and log management", "category": "observability"},
    "new-relic-integration": {"title": "New Relic Monitoring", "desc": "Application performance monitoring and observability", "category": "observability"},
    "splunk-enterprise": {"title": "Splunk Enterprise", "desc": "Machine data analytics and security monitoring", "category": "observability"},
    "pagerduty-integration": {"title": "PagerDuty Incident Management", "desc": "Incident response and on-call management", "category": "observability"},
    
    # testing-components.yaml
    "testing-frameworks": {"title": "Testing Frameworks Suite", "desc": "Comprehensive testing frameworks for unit, integration, and e2e testing", "category": "testing"},
    "sonarqube": {"title": "SonarQube Code Quality", "desc": "Static code analysis and quality gate enforcement", "category": "testing"},
    "security-scanning-suite": {"title": "Security Scanning Suite", "desc": "Vulnerability scanning, SAST, DAST, and dependency analysis", "category": "testing"},
    "performance-testing": {"title": "Performance Testing Suite", "desc": "Load testing, stress testing, and performance monitoring", "category": "testing"},
    "ci-cd-pipelines": {"title": "CI/CD Pipeline Templates", "desc": "Standardized CI/CD pipeline templates for various technologies", "category": "testing"},
    "artifact-repository": {"title": "Artifact Repository", "desc": "Maven, npm, Docker, and generic artifact storage", "category": "testing"},
    
    # data-components.yaml
    "postgresql-cluster": {"title": "PostgreSQL Cluster", "desc": "PostgreSQL database cluster configuration", "category": "data"},
    "mongodb-cluster": {"title": "MongoDB Cluster", "desc": "MongoDB database cluster configuration", "category": "data"},
    "redis-cluster": {"title": "Redis Cluster", "desc": "Redis in-memory data store cluster", "category": "data"},
    "elasticsearch-data": {"title": "Elasticsearch Data", "desc": "Elasticsearch search and analytics engine", "category": "data"},
    "apache-kafka": {"title": "Apache Kafka", "desc": "Distributed event streaming platform", "category": "data"},
    "rabbitmq-cluster": {"title": "RabbitMQ Cluster", "desc": "Message broker for distributed systems", "category": "data"},
    "apache-spark": {"title": "Apache Spark", "desc": "Unified analytics engine for big data", "category": "data"},
    "apache-airflow": {"title": "Apache Airflow", "desc": "Workflow orchestration platform", "category": "data"},
    "zookeeper-ensemble": {"title": "ZooKeeper Ensemble", "desc": "Distributed coordination service", "category": "data"},
    "minio-storage": {"title": "MinIO Storage", "desc": "High-performance object storage", "category": "data"},
    
    # awx components
    "awx-core": {"title": "AWX Core", "desc": "AWX automation controller core components", "category": "awx"},
    "awx-operator": {"title": "AWX Operator", "desc": "Kubernetes operator for AWX deployment", "category": "awx"},
    "awx-helm-chart": {"title": "AWX Helm Chart", "desc": "Helm chart for AWX deployment", "category": "awx"},
}

def create_docs_for_entity(name, info):
    """Create mkdocs.yml and docs/index.md for an entity."""
    entity_dir = CATALOG_DIR / name
    docs_dir = entity_dir / "docs"
    
    # Create directories
    docs_dir.mkdir(parents=True, exist_ok=True)
    
    # Create mkdocs.yml
    mkdocs_content = f"""site_name: {info['title']}
site_description: {info['desc']}

nav:
  - Home: index.md
  - Overview: overview.md
  - Usage: usage.md

plugins:
  - techdocs-core
"""
    
    with open(entity_dir / "mkdocs.yml", "w") as f:
        f.write(mkdocs_content)
    
    # Create docs/index.md
    index_content = f"""# {info['title']}

{info['desc']}

## Quick Start

This documentation provides an overview of the {info['title']} component.

## Features

- Feature 1: Description of feature 1
- Feature 2: Description of feature 2
- Feature 3: Description of feature 3

## Related Documentation

- [Overview](overview.md) - Detailed overview and architecture
- [Usage](usage.md) - How to use this component
"""
    
    with open(docs_dir / "index.md", "w") as f:
        f.write(index_content)
    
    # Create docs/overview.md
    overview_content = f"""# Overview

## Architecture

{info['title']} is designed to provide {info['desc'].lower()}.

## Components

This section describes the main components and their interactions.

## Configuration

Configuration options and environment variables.
"""
    
    with open(docs_dir / "overview.md", "w") as f:
        f.write(overview_content)
    
    # Create docs/usage.md
    usage_content = f"""# Usage Guide

## Getting Started

Follow these steps to get started with {info['title']}.

## Examples

### Basic Usage

```bash
# Example command or code
```

### Advanced Usage

```bash
# Advanced example
```

## Troubleshooting

Common issues and their solutions.
"""
    
    with open(docs_dir / "usage.md", "w") as f:
        f.write(usage_content)
    
    print(f"Created docs for: {name}")

def main():
    print("Creating TechDocs for all entities...")
    
    for name, info in ENTITIES.items():
        create_docs_for_entity(name, info)
    
    print(f"\nCreated docs for {len(ENTITIES)} entities")

if __name__ == "__main__":
    main()
