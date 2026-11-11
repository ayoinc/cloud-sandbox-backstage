# Values chosen in the portal when this repository was created.

project_name    = "${{ values.projectName }}"
environment     = "${{ values.environment }}"
location        = "${{ values.azureRegion }}"
subscription_id = ${{ ('"' + values.azureSubscriptionId + '"') if values.azureSubscriptionId else 'null' }}

kubernetes_version = "${{ values.kubernetesVersion }}"
node_min_count     = ${{ values.minNodes }}
node_max_count     = ${{ values.maxNodes }}
node_size          = "${{ values.nodeSize }}"

# Platform components
enable_gitops                 = ${{ values.enableGitOps | dump }}
enable_observability          = ${{ values.enableObservability | dump }}
enable_service_mesh           = ${{ values.enableServiceMesh | dump }}
enable_cert_manager           = ${{ values.enableCertManager | dump }}
enable_external_dns           = ${{ values.enableExternalDns | dump }}
ingress_controller            = "${{ values.enableIngress }}"
enable_pod_security_standards = ${{ values.enablePodSecurityPolicies | dump }}
enable_network_policies       = ${{ values.enableNetworkPolicies | dump }}
enable_opa                    = ${{ values.enableOPA | dump }}
enable_vault_integration      = ${{ values.enableVaultIntegration | dump }}
