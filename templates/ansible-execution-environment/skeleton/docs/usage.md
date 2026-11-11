# Usage

## ansible-navigator

`ansible-navigator.yml` in this repository points at the published image. Copy
it into a playbook repository, or pass the image on the command line:

```bash
ansible-navigator run site.yml -i inventory/ --execution-environment-image ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
```

Useful commands:

```bash
ansible-navigator collections        # what the image contains
ansible-navigator doc ansible.builtin.copy
ansible-navigator exec -- ansible --version
```

Only the environment variables listed under `environment-variables.pass` reach
the container. Add the ones your inventory or lookups need; do not write values
into the file.

SSH keys are best supplied through an agent: `SSH_AUTH_SOCK` is passed through
and ansible-navigator mounts the socket.

## Pulling from the registry

The package is private by default.

```bash
echo "$GITHUB_TOKEN" | podman login ghcr.io --username <user> --password-stdin
podman pull ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
```

A token needs the `read:packages` scope. For automation, prefer a GitHub App
or a workflow's own token over a personal one.

## Pinning

| Reference | Changes when |
| --- | --- |
| `:latest` | Every push to `main` |
| `:1.2` | A patch release is tagged |
| `:1.2.3`, `:sha-<commit>` | Never, unless the tag is deleted |
| `@sha256:<digest>` | Never |

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `couldn't resolve module/action` | The collection is not in `requirements.yml`; add it and rebuild |
| A Python import fails in a module that runs on localhost | Add the package to `requirements.txt` |
| `ssh: command not found` or similar | Add the system package to `bindep.txt` |
| The vulnerability scan stops the build | Raise the affected pin; a finding without a fix is not reported |
