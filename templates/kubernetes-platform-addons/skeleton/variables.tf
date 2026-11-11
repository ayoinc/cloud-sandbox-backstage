# =============================================================================
# Kubernetes Platform Add-ons - Variables
# =============================================================================

variable "name" {
  description = "Name of this add-on set, usually the name of the cluster. ExternalDNS marks its records with it."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Use lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment of the cluster: dev, staging or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "description" {
  description = "Purpose of the add-on set, added to the namespaces as an annotation."
  type        = string
}

variable "owner" {
  description = "Team that owns the add-ons, added to the namespaces as an annotation."
  type        = string
}

variable "kube_context" {
  description = "Context of the kubeconfig to use. Null uses the current context."
  type        = string
  default     = null
}

variable "high_availability" {
  description = "Run two replicas of every add-on, with pod disruption budgets."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Ingress controller (Traefik)
# -----------------------------------------------------------------------------

variable "enable_ingress" {
  description = "Install Traefik as the ingress controller and default IngressClass."
  type        = bool
  default     = true
}

variable "traefik_chart_version" {
  description = "Version of the traefik Helm chart."
  type        = string
  default     = "42.3.1"
}

variable "ingress_service_annotations" {
  description = "Annotations of the load balancer Service, for instance to choose an internal or a specific type of cloud load balancer."
  type        = map(string)
  default     = {}
}

variable "enable_gateway_api" {
  description = "Also serve Gateway API routes. The Gateway API CRDs must already be installed in the cluster."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# cert-manager
# -----------------------------------------------------------------------------

variable "enable_cert_manager" {
  description = "Install cert-manager and the Let's Encrypt ClusterIssuers."
  type        = bool
  default     = true
}

variable "cert_manager_chart_version" {
  description = "Version of the cert-manager Helm chart."
  type        = string
  default     = "v1.21.3"
}

variable "acme_email" {
  description = "Address Let's Encrypt sends expiry warnings to."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.acme_email))
    error_message = "Give a valid e-mail address."
  }
}

variable "ingress_class_name" {
  description = "IngressClass that answers the HTTP-01 challenges of Let's Encrypt."
  type        = string
  default     = "traefik"
}

# -----------------------------------------------------------------------------
# ExternalDNS
# -----------------------------------------------------------------------------

variable "enable_external_dns" {
  description = "Install ExternalDNS."
  type        = bool
  default     = true
}

variable "external_dns_chart_version" {
  description = "Version of the external-dns Helm chart."
  type        = string
  default     = "1.23.0"
}

variable "dns_provider" {
  description = "DNS provider: cloudflare, digitalocean, aws, google or azure."
  type        = string
  default     = "cloudflare"

  validation {
    condition     = contains(["cloudflare", "digitalocean", "aws", "google", "azure"], var.dns_provider)
    error_message = "The DNS provider must be cloudflare, digitalocean, aws, google or azure."
  }
}

variable "dns_domain_filters" {
  description = "Domains ExternalDNS may manage records under. An empty list allows every zone the credentials can reach."
  type        = list(string)
  default     = []
}

variable "dns_policy" {
  description = "upsert-only never deletes records; sync also removes records whose Ingress or Service is gone."
  type        = string
  default     = "upsert-only"

  validation {
    condition     = contains(["upsert-only", "sync"], var.dns_policy)
    error_message = "The DNS policy must be upsert-only or sync."
  }
}

variable "dns_api_token" {
  description = "API token of the cloudflare or digitalocean provider. Supplied as TF_VAR_dns_api_token; it is written to a Secret in the cluster and never to the Terraform state."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "dns_api_token_revision" {
  description = "Increase this number to write a rotated DNS API token to the cluster."
  type        = number
  default     = 1
}

variable "dns_service_account_annotations" {
  description = "Annotations of the ExternalDNS service account. The aws, google and azure providers authenticate through the workload identity they configure."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Metrics Server
# -----------------------------------------------------------------------------

variable "enable_metrics_server" {
  description = "Install Metrics Server. Leave it off on clusters that ship it."
  type        = bool
  default     = true
}

variable "metrics_server_chart_version" {
  description = "Version of the metrics-server Helm chart."
  type        = string
  default     = "3.14.0"
}

variable "metrics_server_kubelet_insecure_tls" {
  description = "Skip verification of the kubelet certificates. Only for clusters whose kubelets use self-signed certificates, such as kind or k3d."
  type        = bool
  default     = false
}
