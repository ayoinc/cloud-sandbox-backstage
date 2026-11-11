# Ansible k3s Cluster

Creates a playbook repository that builds and operates a highly available k3s
Kubernetes cluster on machines you already have: three or more servers with
embedded etcd, any number of agents, and optionally a kube-vip virtual IP in
front of the API.

## What you get

| Path                        | Purpose                                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------------------------- |
| `inventory/`                | The servers and agents entered in the form, and the cluster settings                                      |
| `playbooks/site.yml`        | Prepare hosts, bootstrap the first server, join the others one at a time, join agents, fetch a kubeconfig |
| `playbooks/upgrade.yml`     | Rolling upgrade: servers first, one node at a time, each drained and uncordoned                           |
| `playbooks/reset.yml`       | Remove k3s from every node, behind an explicit confirmation                                               |
| `roles/k3s_prereq/`         | Kernel modules, sysctl values, packages and firewall rules k3s needs                                      |
| `roles/k3s/`                | Version-pinned install, configuration, kube-vip manifest, service and readiness checks                    |
| `.github/workflows/ci.yaml` | yamllint, ansible-lint (`production` profile), inventory and syntax checks                                |

## Parameters

| Parameter          | Description                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| k3s version        | Exact release to install, for example `v1.37.2+k3s1`                                              |
| Servers            | Control-plane hosts. Use an odd number; three tolerate the loss of one                            |
| Agents             | Worker hosts; may be empty                                                                        |
| API endpoint       | Address clients and agents use for the API: the kube-vip virtual IP, or an existing load balancer |
| kube-vip           | Deploy kube-vip to announce the endpoint address from whichever server leads                      |
| Bundled components | Keep or drop Traefik and the ServiceLB load balancer                                              |

## Defaults worth knowing

- Secrets are encrypted at rest and the kubeconfig is readable by root only
- The install script comes from the tagged k3s release and verifies the binary's checksum
- The cluster token is never in the repository; it is read from Ansible Vault
- etcd snapshots are taken every six hours on each server

## After scaffolding

1. Create the vault holding the cluster token (the README shows how).
2. Make sure the SSH user can reach every host and escalate with sudo.
3. Run `ansible-playbook playbooks/site.yml`.
