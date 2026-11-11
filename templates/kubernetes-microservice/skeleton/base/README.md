# ${{ values.name }}

${{ values.description }}

{% if values.language == 'nodejs' %}Node.js{% elif values.language == 'python' %}Python{% elif values.language == 'java' %}Java{% elif values.language == 'golang' %}Go{% else %}.NET{% endif %} microservice with Kubernetes manifests and a pipeline.

## Getting started

```bash
docker build -t ${{ values.name }}:local .
docker run --rm -p 8080:8080 ${{ values.name }}:local
```

```bash
curl http://localhost:8080/
curl http://localhost:8080/health
```

## Commands

- `docker build --target test .` runs the unit tests inside the image build
- `bash scripts/render-manifests.sh` prints the Kubernetes manifests
- `bash scripts/validate-manifests.sh` validates them with kubeconform
{%- if values.enable_policy_enforcement %}
- `bash scripts/check-policies.sh` checks them against the policies in `policy/`
{%- endif %}
{%- if values.enable_automated_testing %}
- `bash scripts/kind-test.sh ${{ values.name }}:local` deploys the image to a throwaway kind cluster
{%- endif %}
- `bash scripts/deploy.sh <image>` applies the manifests to the current kubectl context

## Documentation

`docs/index.md` describes the service, the manifests, the pipeline and how to
enable deployment; it is published as TechDocs in the developer portal.

## Owner

${{ values.owner }}
