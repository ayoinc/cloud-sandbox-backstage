# Configuration

Cluster settings live in `inventory/group_vars/k3s_cluster/main.yml`. Any
variable below can be set there, or per host in `inventory/host_vars/`.

## k3s role

| Variable | Type | Description |
| --- | --- | --- |
| `k3s_version` | str | Exact k3s release, for example v1.37.2+k3s1. |
| `k3s_node_type` | str | Whether the host is a server or an agent. |
| `k3s_token` | str | Shared join secret. Supply it from Ansible Vault. |
| `k3s_api_endpoint` | str | Address clients and agents use for the Kubernetes API. |
| `k3s_api_port` | int | Port of the Kubernetes API. |
| `k3s_node_name` | str | Name the node registers with. Defaults to the short host name. |
| `k3s_first_server` | str | Inventory name of the server that bootstraps the cluster. |
| `k3s_first_server_address` | str | Address joining servers contact. |
| `k3s_tls_san_extra` | list of str | Further names or addresses the API certificate must be valid for. |
| `k3s_disable` | list of str | Bundled components to leave out. |
| `k3s_cluster_cidr` | str | Pod network. |
| `k3s_service_cidr` | str | Service network. |
| `k3s_etcd_snapshot_schedule` | str | Cron expression for etcd snapshots. |
| `k3s_etcd_snapshot_retention` | int | Snapshots kept on each server. |
| `k3s_server_config_extra` | dict | Options merged over the generated server configuration. |
| `k3s_agent_config_extra` | dict | Options merged over the generated agent configuration. |
| `k3s_kube_vip_enabled` | bool | Deploy kube-vip to announce the API endpoint as a virtual IP. |
| `k3s_kube_vip_version` | str | kube-vip image tag. |
| `k3s_kube_vip_interface` | str | Interface on the servers that carries the virtual IP. |
| `k3s_ready_timeout` | int | Seconds to wait for a node to become ready. |

### Passing further k3s options

Anything k3s accepts in `/etc/rancher/k3s/config.yaml` can be added without
changing the role:

```yaml
k3s_server_config_extra:
  kube-apiserver-arg:
    - audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log
    - audit-log-maxage=30
k3s_agent_config_extra:
  node-label:
    - topology.kubernetes.io/zone=rack-a
```

## k3s_prereq role

| Variable | Type | Description |
| --- | --- | --- |
| `k3s_prereq_manage_firewall` | bool | Open the k3s ports when firewalld or ufw is running |
| `k3s_prereq_cluster_cidr` | str | Pod network allowed through the host firewall; keep equal to `k3s_cluster_cidr` |
| `k3s_prereq_service_cidr` | str | Service network allowed through the host firewall; keep equal to `k3s_service_cidr` |
| `k3s_prereq_sysctl` | dict | Kernel parameters set and persisted |
