terraform {
  required_version = ">= 1.0"

  required_providers {
    {%- if values.cloudProvider == "aws" %}
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    {%- endif %}
    {%- if values.cloudProvider == "azure" %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    {%- endif %}
    {%- if values.cloudProvider == "gcp" %}
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    {%- endif %}
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }

  {%- if values.cloudProvider == "aws" %}
  backend "s3" {
    bucket = "${{ values.projectName }}-terraform-state"
    key    = "${{ values.environment }}/kubernetes/terraform.tfstate"
    region = "${{ values.awsRegion }}"
  }
  {%- endif %}
  {%- if values.cloudProvider == "azure" %}
  backend "azurerm" {
    resource_group_name  = "${{ values.projectName }}-terraform-state-rg"
    storage_account_name = "${{ values.projectName | replace("-", "") }}tfstate"
    container_name       = "tfstate"
    key                  = "${{ values.environment }}/kubernetes/terraform.tfstate"
  }
  {%- endif %}
  {%- if values.cloudProvider == "gcp" %}
  backend "gcs" {
    bucket = "${{ values.projectName }}-terraform-state"
    prefix = "${{ values.environment }}/kubernetes"
  }
  {%- endif %}
}

{%- if values.cloudProvider == "aws" %}
provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
provider "google" {
  project = var.gcp_project_id
  region  = var.region
}
{%- endif %}

locals {
  name_prefix = "${{ values.projectName }}-${{ values.environment }}"
  
  common_tags = {
    Project     = "${{ values.projectName }}"
    Environment = "${{ values.environment }}"
    ManagedBy   = "terraform"
    Platform    = "kubernetes"
  }

  {%- if values.nodePoolConfig.nodeSize == "small" %}
  node_instance_type = {
    aws   = "t3.medium"
    azure = "Standard_D2s_v3"
    gcp   = "e2-medium"
  }
  {%- elif values.nodePoolConfig.nodeSize == "medium" %}
  node_instance_type = {
    aws   = "t3.xlarge"
    azure = "Standard_D4s_v3"
    gcp   = "e2-standard-4"
  }
  {%- else %}
  node_instance_type = {
    aws   = "t3.2xlarge"
    azure = "Standard_D8s_v3"
    gcp   = "e2-standard-8"
  }
  {%- endif %}
}

# =============================================================================
# NETWORKING
# =============================================================================

{%- if values.cloudProvider == "aws" %}
module "vpc" {
  source = "../../aws/resources/network/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  public_subnets = [
    { cidr = cidrsubnet(var.vpc_cidr, 4, 0), az = "${var.region}a" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 1), az = "${var.region}b" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 2), az = "${var.region}c" }
  ]

  private_subnets = [
    { cidr = cidrsubnet(var.vpc_cidr, 4, 4), az = "${var.region}a" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 5), az = "${var.region}b" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 6), az = "${var.region}c" }
  ]

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "resource_group" {
  source = "../../azure/resources/core/resource-group"

  name     = "${local.name_prefix}-rg"
  location = var.region

  tags = local.common_tags
}

module "vnet" {
  source = "../../azure/resources/network/vnet"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  vnet_name     = "${local.name_prefix}-vnet"
  address_space = [var.vpc_cidr]

  subnets = [
    {
      name             = "${local.name_prefix}-aks-subnet"
      address_prefixes = [cidrsubnet(var.vpc_cidr, 4, 0)]
    },
    {
      name             = "${local.name_prefix}-services-subnet"
      address_prefixes = [cidrsubnet(var.vpc_cidr, 4, 1)]
    }
  ]

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "vpc" {
  source = "../../gcp/resources/network/vpc"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  network_name = "${local.name_prefix}-vpc"
  
  subnets = [
    {
      name          = "${local.name_prefix}-gke-subnet"
      ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 0)
      region        = var.region
      purpose       = "gke"
    },
    {
      name          = "${local.name_prefix}-services-subnet"
      ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 1)
      region        = var.region
      purpose       = "services"
    }
  ]

  enable_nat_gateway = true
  
  labels = local.common_tags
}
{%- endif %}

# =============================================================================
# KUBERNETES CLUSTER
# =============================================================================

{%- if values.cloudProvider == "aws" %}
module "eks" {
  source = "../../aws/resources/kubernetes/eks"

  project_name = var.project_name
  environment  = var.environment

  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    default = {
      instance_types = [local.node_instance_type["aws"]]
      min_size       = var.min_nodes
      max_size       = var.max_nodes
      desired_size   = var.min_nodes
      
      labels = {
        role = "worker"
      }
    }
  }

  enable_cluster_autoscaler = true
  enable_metrics_server     = true

  tags = local.common_tags
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "aks" {
  source = "../../azure/resources/kubernetes/aks"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  cluster_name       = "${local.name_prefix}-aks"
  kubernetes_version = var.kubernetes_version
  dns_prefix         = local.name_prefix

  default_node_pool = {
    name                = "default"
    vm_size             = local.node_instance_type["azure"]
    min_count           = var.min_nodes
    max_count           = var.max_nodes
    enable_auto_scaling = true
    vnet_subnet_id      = module.vnet.subnet_ids[0]
  }

  network_profile = {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "gke" {
  source = "../../gcp/resources/kubernetes/gke"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  cluster_name = "${local.name_prefix}-gke"
  location     = var.region
  
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnet_names[0]

  enable_autopilot = false
  
  node_pools = [
    {
      name           = "default-pool"
      machine_type   = local.node_instance_type["gcp"]
      min_node_count = var.min_nodes
      max_node_count = var.max_nodes
      disk_size_gb   = 100
      preemptible    = var.environment != "production"
    }
  ]

  master_ipv4_cidr_block = "172.16.0.0/28"
  
  enable_private_nodes    = true
  enable_private_endpoint = false

  labels = local.common_tags
}

data "google_client_config" "default" {}
{%- endif %}

# Configure Kubernetes and Helm providers
provider "kubernetes" {
  {%- if values.cloudProvider == "aws" %}
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
  {%- endif %}
  {%- if values.cloudProvider == "azure" %}
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  {%- endif %}
  {%- if values.cloudProvider == "gcp" %}
  host                   = "https://${module.gke.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
  {%- endif %}
}

provider "helm" {
  kubernetes {
    {%- if values.cloudProvider == "aws" %}
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster.token
    {%- endif %}
    {%- if values.cloudProvider == "azure" %}
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
    {%- endif %}
    {%- if values.cloudProvider == "gcp" %}
    host                   = "https://${module.gke.cluster_endpoint}"
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
    {%- endif %}
  }
}

# =============================================================================
# PLATFORM COMPONENTS
# =============================================================================

{%- if values.enableIngress != "none" %}
# Ingress Controller
resource "helm_release" "ingress" {
  name             = "ingress-${{ values.enableIngress }}"
  repository       = {%- if values.enableIngress == "nginx" %}"https://kubernetes.github.io/ingress-nginx"{%- else %}"https://traefik.github.io/charts"{%- endif %}
  chart            = {%- if values.enableIngress == "nginx" %}"ingress-nginx"{%- else %}"traefik"{%- endif %}
  namespace        = "ingress-system"
  create_namespace = true
  version          = {%- if values.enableIngress == "nginx" %}"4.9.0"{%- else %}"26.0.0"{%- endif %}

  values = [
    yamlencode({
      controller = {
        replicaCount = var.environment == "production" ? 3 : 2
        service = {
          type = "LoadBalancer"
          annotations = {
            {%- if values.cloudProvider == "aws" %}
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
            {%- endif %}
            {%- if values.cloudProvider == "azure" %}
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
            {%- endif %}
          }
        }
        metrics = {
          enabled = true
        }
      }
    })
  ]
}
{%- endif %}

{%- if values.enableCertManager %}
# Cert-Manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "1.14.0"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }
}
{%- endif %}

{%- if values.enableGitOps %}
# ArgoCD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.53.0"

  values = [
    yamlencode({
      server = {
        replicas = var.environment == "production" ? 2 : 1
        service = {
          type = "LoadBalancer"
        }
        ingress = {
          enabled = ${{ values.enableIngress != "none" }}
        }
      }
      controller = {
        replicas = var.environment == "production" ? 2 : 1
      }
      repoServer = {
        replicas = var.environment == "production" ? 2 : 1
      }
      applicationSet = {
        enabled = true
      }
      notifications = {
        enabled = true
      }
    })
  ]
}
{%- endif %}

{%- if values.enableObservability %}
# Prometheus Stack (includes Grafana)
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "56.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = var.environment == "production" ? "30d" : "7d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.environment == "production" ? "100Gi" : "20Gi"
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = true
          size    = "10Gi"
        }
        ingress = {
          enabled = ${{ values.enableIngress != "none" }}
        }
      }
      alertmanager = {
        enabled = true
      }
    })
  ]
}

# Loki for log aggregation
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "2.10.0"

  values = [
    yamlencode({
      loki = {
        persistence = {
          enabled = true
          size    = var.environment == "production" ? "50Gi" : "10Gi"
        }
      }
      promtail = {
        enabled = true
      }
    })
  ]

  depends_on = [helm_release.prometheus]
}
{%- endif %}

{%- if values.enableServiceMesh %}
# Istio Service Mesh
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.20.0"
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = "1.20.0"

  values = [
    yamlencode({
      pilot = {
        traceSampling = var.environment == "production" ? 1 : 100
      }
      meshConfig = {
        enableTracing = true
        accessLogFile = "/dev/stdout"
      }
    })
  ]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  version    = "1.20.0"

  depends_on = [helm_release.istiod]
}
{%- endif %}

{%- if values.enableExternalDns %}
# External-DNS
resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  version          = "1.14.0"

  values = [
    yamlencode({
      provider = "${{ values.cloudProvider }}"
      {%- if values.cloudProvider == "aws" %}
      aws = {
        zoneType = "public"
      }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns[0].arn
        }
      }
      {%- endif %}
      {%- if values.cloudProvider == "azure" %}
      azure = {
        resourceGroup = module.resource_group.name
      }
      {%- endif %}
      {%- if values.cloudProvider == "gcp" %}
      google = {
        project = var.gcp_project_id
      }
      {%- endif %}
      policy = "sync"
      txtOwnerId = local.name_prefix
    })
  ]
}

{%- if values.cloudProvider == "aws" %}
resource "aws_iam_role" "external_dns" {
  count = 1
  name  = "${local.name_prefix}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-dns:external-dns"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "external_dns" {
  count = 1
  name  = "${local.name_prefix}-external-dns"
  role  = aws_iam_role.external_dns[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}
{%- endif %}
{%- endif %}

{%- if values.enableOPA %}
# OPA Gatekeeper
resource "helm_release" "gatekeeper" {
  name             = "gatekeeper"
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart            = "gatekeeper"
  namespace        = "gatekeeper-system"
  create_namespace = true
  version          = "3.14.0"

  values = [
    yamlencode({
      replicas = var.environment == "production" ? 3 : 1
      audit = {
        replicas = 1
      }
    })
  ]
}
{%- endif %}

{%- if values.enableNetworkPolicies %}
# Default Network Policies
resource "kubernetes_network_policy" "default_deny_ingress" {
  metadata {
    name      = "default-deny-ingress"
    namespace = "default"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow_same_namespace" {
  metadata {
    name      = "allow-same-namespace"
    namespace = "default"
  }

  spec {
    pod_selector {}

    ingress {
      from {
        pod_selector {}
      }
    }

    policy_types = ["Ingress"]
  }
}
{%- endif %}
