# ${{ values.name }}

${{ values.description }}

## Cluster

| | |
| --- | --- |
| k3s version | `${{ values.k3sVersion }}` |
| API endpoint | `https://${{ values.apiEndpoint }}:6443` |
| API high availability | ${{ 'kube-vip virtual IP on ' + values.kubeVipInterface if values.enableKubeVip else 'external load balancer' }} |
| Datastore | Embedded etcd on the servers |
| Servers | ${{ values.servers | join(', ') }} |
| Agents | ${{ values.agents | join(', ') if values.agents | length else 'none' }} |
| Owner | `${{ values.owner }}` |

## How the cluster is built

1. **Prepare** - every node gets the kernel modules, kernel parameters and firewall openings k3s needs.
2. **First server** - installs k3s with `cluster-init`, which starts a one-member etcd cluster{% if values.enableKubeVip %}, and applies the kube-vip manifest so the virtual IP comes up{% endif %}.
3. **Other servers** - join through the first server, one at a time, each waiting until it is ready.
4. **Agents** - register through the API endpoint.
5. **Kubeconfig** - an admin kubeconfig pointing at the API endpoint is written to `kubeconfig/config`.

Every step checks before it changes: a node already on the right version with
the right configuration is not restarted.

## Layout

```
ansible.cfg
inventory/
├── hosts.yml                       # server and agent groups
└── group_vars/
    ├── k3s_cluster/main.yml        # version, endpoint, kube-vip, components
    ├── k3s_cluster/vault.yml       # the join token, encrypted (you create it)
    ├── server.yml
    └── agent.yml
playbooks/
├── site.yml
├── upgrade.yml
└── reset.yml
roles/
├── k3s_prereq/                     # host preparation
└── k3s/                            # install, configure, start, wait
```
