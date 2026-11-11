# Operations

## Upgrade

1. Read the k3s release notes for the target version.
2. Set `k3s_version` in `inventory/group_vars/k3s_cluster/main.yml`.
3. Run `ansible-playbook playbooks/upgrade.yml`.

The playbook refuses downgrades and jumps of more than one minor version,
saves an etcd snapshot named `pre-upgrade`, then upgrades servers and after
them agents. Each node is drained, upgraded, waited for and uncordoned before
the next one starts.

A drain that cannot finish, usually because of a PodDisruptionBudget, stops
the run with that node cordoned. Resolve it, then run the playbook again;
nodes already on the target version are skipped quickly.

Skip draining for a cluster where brief pod restarts are acceptable:

```bash
ansible-playbook playbooks/upgrade.yml -e k3s_upgrade_drain=false
```

## etcd snapshots

Each server takes a snapshot every six hours and keeps twenty, under
`/var/lib/rancher/k3s/server/db/snapshots/`.

```bash
sudo k3s etcd-snapshot ls
sudo k3s etcd-snapshot save --name before-change
```

Snapshots on the servers do not survive losing the servers. Copy them
elsewhere, or let k3s upload them to object storage:

```yaml
# inventory/group_vars/k3s_cluster/main.yml
k3s_server_config_extra:
  etcd-s3: true
  etcd-s3-endpoint: s3.eu-west-2.amazonaws.com
  etcd-s3-bucket: my-cluster-snapshots
  etcd-s3-region: eu-west-2
```

Supply S3 credentials from the vault, or use instance credentials where the
platform provides them.

## Restore

Restoring replaces the cluster's state with the snapshot's.

```bash
# On every server
sudo systemctl stop k3s

# On the first server
sudo k3s server --cluster-reset --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/<snapshot>
sudo systemctl start k3s

# On each other server: discard its old etcd member data, then rejoin
sudo rm -rf /var/lib/rancher/k3s/server/db
sudo systemctl start k3s
```

Also keep a copy of `/var/lib/rancher/k3s/server/token` from a server: a
snapshot can only be restored with the token of the cluster it came from.

## Replace a server

1. `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
2. `kubectl delete node <node>`; k3s removes its etcd member
3. `ansible-playbook playbooks/reset.yml --limit <host> -e k3s_reset_confirm=yes` if the machine is still reachable
4. Replace the host in `inventory/hosts.yml` and run `playbooks/site.yml`

Do not replace the first server in the inventory with an empty machine while
it is still listed first: the first entry is the one that bootstraps. Move
another, healthy server to the top first.

## Reset

```bash
ansible-playbook playbooks/reset.yml -e k3s_reset_confirm=yes
```

Removes k3s, its data and its configuration from every node in the inventory,
and the local kubeconfig. Persistent volume data stored on the nodes by the
local-path provisioner is deleted with it.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| A server never becomes ready | `journalctl -u k3s -e` on that server; ports 6443 and 2379-2380 open between servers |
| An agent never becomes ready | `journalctl -u k3s-agent -e`; the agent can reach the API endpoint on 6443 and other nodes on 8472/udp |
| The virtual IP does not answer | `kubectl -n kube-system logs ds/kube-vip-ds`; the interface name matches on every server; the address is not in use elsewhere |
| Kubelet refuses to start over kernel parameters | Run `site.yml` again; `k3s_prereq` restores the expected values |
