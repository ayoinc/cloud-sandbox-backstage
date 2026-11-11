# ${{ values.name }}

${{ values.description }}

Ansible playbooks for a highly available k3s cluster: ${{ values.servers | length }} server(s) with
embedded etcd and ${{ values.agents | length }} agent(s), k3s ${{ values.k3sVersion }}, API at
`${{ values.apiEndpoint }}`{% if values.enableKubeVip %} announced by kube-vip{% endif %}.

| Playbook | Purpose |
| --- | --- |
| `playbooks/site.yml` | Build the cluster, or bring it back to the declared state |
| `playbooks/upgrade.yml` | Rolling upgrade to the version in inventory |
| `playbooks/reset.yml` | Remove k3s from the nodes |

## Requirements

- A control machine with Python 3.13 or newer
- Nodes running Ubuntu 24.04 or 26.04, Debian 12 or 13, or Enterprise Linux 9 or 10, on x86_64 or aarch64
- SSH access as `${{ values.ansibleUser }}` with passwordless sudo, and the nodes' host keys in `known_hosts`
- Outbound HTTPS from the nodes to `github.com`, `raw.githubusercontent.com` and the container registries
{%- if values.enableKubeVip %}
- `${{ values.apiEndpoint }}` unused and in the same layer-2 network as the servers, which all have the interface `${{ values.kubeVipInterface }}`
{%- else %}
- A TCP load balancer at `${{ values.apiEndpoint }}` forwarding port 6443 to every server
{%- endif %}
- An odd number of servers. Three tolerate the loss of one; one or two tolerate none

## First run

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml

# The cluster token: generated once, stored encrypted, never committed in clear
printf 'vault_k3s_token: %s\n' "$(openssl rand -hex 32)" > inventory/group_vars/k3s_cluster/vault.yml
ansible-vault encrypt inventory/group_vars/k3s_cluster/vault.yml

ansible k3s_cluster -m ansible.builtin.ping --ask-vault-pass
ansible-playbook playbooks/site.yml --ask-vault-pass
```

Commit the encrypted `vault.yml`. To avoid typing the vault password, point
`ANSIBLE_VAULT_PASSWORD_FILE` at a file outside the repository, or at a script
that reads it from your secrets manager.

When the playbook finishes, an admin kubeconfig is in `kubeconfig/config`
(ignored by git):

```bash
export KUBECONFIG=$PWD/kubeconfig/config
kubectl get nodes
```

That file grants cluster-admin. Keep it as carefully as a password and issue
people their own, narrower credentials.

## Changing the cluster

| To | Do |
| --- | --- |
| Add a node | Add it to `inventory/hosts.yml`, run `site.yml` |
| Change a k3s option | Edit `inventory/group_vars/k3s_cluster/main.yml`, run `site.yml`; servers restart one at a time, agents a quarter at a time |
| Upgrade k3s | Set `k3s_version`, run `upgrade.yml` |
| Remove a node | `kubectl drain` and `kubectl delete node`, then `reset.yml --limit <host> -e k3s_reset_confirm=yes`, then remove it from the inventory |

`docs/operations.md` covers upgrades, etcd snapshots, restore and reset in
detail; `docs/configuration.md` lists every variable.

## Security defaults

- Kubernetes secrets are encrypted at rest (`secrets-encryption`)
- The kubelet refuses to start if kernel parameters differ from what it expects (`protect-kernel-defaults`)
- The node kubeconfig and the k3s configuration, which holds the join token, are readable by root only
- The installer is fetched from the tagged k3s release and verifies the binary's checksum
- SSH host keys are checked

## Continuous integration

`.github/workflows/ci.yaml` runs yamllint, ansible-lint with the `production`
profile, an inventory check and a syntax check of every playbook on each push
to `main`. It never connects to the nodes.

## Owner

${{ values.owner }}
