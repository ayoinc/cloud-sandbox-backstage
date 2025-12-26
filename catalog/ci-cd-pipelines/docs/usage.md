# Usage Guide

## Getting Started

### Prerequisites

| Requirement    | Platform    | Description                 |
| -------------- | ----------- | --------------------------- |
| GitHub Actions | GitHub      | Enabled by default          |
| GitLab CI      | GitLab      | Runners configured          |
| Jenkins        | Self-hosted | Jenkins controller + agents |
| Docker         | All         | Container runtime           |
| kubectl        | All         | Kubernetes CLI              |
| Helm           | All         | Package manager             |

### Quick Integration

```bash
# Clone shared workflows repository
git clone https://github.com/company/shared-workflows.git

# Copy template to your project
cp shared-workflows/examples/node-ci.yaml .github/workflows/ci.yaml

# Customize for your project
# Edit .github/workflows/ci.yaml
```

## Examples

### Node.js Application CI/CD

```yaml
# .github/workflows/ci.yaml
name: Node.js CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run test:coverage
        env:
          DATABASE_URL: postgres://postgres:test@localhost:5432/test
          REDIS_URL: redis://localhost:6379

      - uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  build:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha
            type=ref,event=branch

      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    runs-on: ubuntu-latest
    needs: build
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - uses: azure/setup-helm@v3

      - name: Deploy to staging
        run: |
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          helm upgrade --install app charts/app \
            --namespace staging \
            --set image.tag=${{ github.sha }} \
            --wait

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment: production
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - uses: azure/setup-helm@v3

      - name: Deploy to production
        run: |
          echo "${{ secrets.KUBECONFIG_PROD }}" | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          helm upgrade --install app charts/app \
            --namespace production \
            --set image.tag=${{ github.sha }} \
            --wait
```

### Python Application CI/CD

```yaml
# .github/workflows/python-ci.yaml
name: Python CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  PYTHON_VERSION: '3.12'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      - run: pip install ruff black mypy
      - run: ruff check .
      - run: black --check .
      - run: mypy src/

  test:
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'

      - run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov pytest-asyncio

      - run: pytest --cov=src --cov-report=xml

      - uses: codecov/codecov-action@v4
        if: matrix.python-version == '3.12'

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      - run: pip install bandit safety
      - run: bandit -r src/
      - run: safety check -r requirements.txt

  build:
    runs-on: ubuntu-latest
    needs: [test, security]
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

### Go Application CI/CD

```yaml
# .github/workflows/go-ci.yaml
name: Go CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  GO_VERSION: '1.22'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
      - uses: golangci/golangci-lint-action@v4
        with:
          version: latest

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}

      - run: go test -v -race -coverprofile=coverage.out ./...
      - run: go tool cover -html=coverage.out -o coverage.html

      - uses: codecov/codecov-action@v4
        with:
          files: coverage.out

  build:
    runs-on: ubuntu-latest
    needs: test
    strategy:
      matrix:
        goos: [linux, darwin, windows]
        goarch: [amd64, arm64]
        exclude:
          - goos: windows
            goarch: arm64

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}

      - name: Build binary
        run: |
          GOOS=${{ matrix.goos }} GOARCH=${{ matrix.goarch }} \
          go build -ldflags="-s -w" -o dist/app-${{ matrix.goos }}-${{ matrix.goarch }} ./cmd/app

      - uses: actions/upload-artifact@v4
        with:
          name: app-${{ matrix.goos }}-${{ matrix.goarch }}
          path: dist/
```

### Terraform CI/CD

```yaml
# .github/workflows/terraform.yaml
name: Terraform

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'

env:
  TF_VERSION: '1.7.0'
  AWS_REGION: 'us-west-2'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format
        run: terraform fmt -check -recursive
        working-directory: terraform

      - name: Terraform Init
        run: terraform init -backend=false
        working-directory: terraform

      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform

  plan:
    runs-on: ubuntu-latest
    needs: validate
    if: github.event_name == 'pull_request'
    permissions:
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: terraform

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color -out=tfplan
        working-directory: terraform

      - name: Comment Plan
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan
            \`\`\`
            ${{ steps.plan.outputs.stdout }}
            \`\`\`
            `;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

  apply:
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: terraform
```

### Matrix Build Strategy

```yaml
# .github/workflows/matrix.yaml
name: Matrix Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node: [18, 20, 22]
        include:
          - os: ubuntu-latest
            node: 20
            coverage: true
        exclude:
          - os: windows-latest
            node: 18

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'

      - run: npm ci
      - run: npm test

      - name: Upload coverage
        if: matrix.coverage
        uses: codecov/codecov-action@v4
```

## Secrets Management

### GitHub Secrets

```bash
# Set repository secret via CLI
gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"

# Set organization secret
gh secret set DOCKER_PASSWORD --org company --visibility all

# List secrets
gh secret list
```

### Using Secrets in Workflows

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Configure credentials
        run: |
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > ~/.kube/config

      - name: Deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
        run: ./deploy.sh
```

### External Secrets with Vault

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Import secrets from Vault
        uses: hashicorp/vault-action@v2
        with:
          url: https://vault.company.com
          method: jwt
          role: github-actions
          secrets: |
            secret/data/myapp/prod database_url | DATABASE_URL ;
            secret/data/myapp/prod api_key | API_KEY

      - name: Deploy with secrets
        run: ./deploy.sh
        env:
          DATABASE_URL: ${{ env.DATABASE_URL }}
          API_KEY: ${{ env.API_KEY }}
```

## Troubleshooting

| Issue                    | Cause                   | Solution                              |
| ------------------------ | ----------------------- | ------------------------------------- |
| `Permission denied`      | Missing permissions     | Add required permissions to job       |
| `Secret not found`       | Secret not set          | Set secret in repository/org settings |
| `Workflow not triggered` | Wrong event/paths       | Check `on` trigger configuration      |
| `Cache not restored`     | Key mismatch            | Verify cache key matches              |
| `Docker build failed`    | BuildKit issue          | Ensure Docker Buildx is set up        |
| `Deployment timeout`     | Slow rollout            | Increase timeout or check pods        |
| `Rate limited`           | Too many API calls      | Add delays or use matrix throttling   |
| `Runner offline`         | Self-hosted runner down | Check runner status and logs          |

### Debug Workflows

```yaml
# Enable debug logging
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true

# Add debug step
- name: Debug info
  run: |
    echo "Event: ${{ github.event_name }}"
    echo "Ref: ${{ github.ref }}"
    echo "SHA: ${{ github.sha }}"
    echo "Actor: ${{ github.actor }}"
    env
```

### Re-run Failed Jobs

```bash
# Re-run failed jobs via CLI
gh run rerun 12345 --failed

# Re-run specific job
gh run rerun 12345 --job build
```

## Best Practices

### Workflow Organization

- [ ] Use reusable workflows for common patterns
- [ ] Keep workflows focused and modular
- [ ] Use meaningful job and step names
- [ ] Add concurrency controls to prevent duplicates

### Security

- [ ] Never hardcode secrets in workflows
- [ ] Use least-privilege permissions
- [ ] Pin action versions with SHA
- [ ] Scan for secrets in commits
- [ ] Use environment protection rules

### Performance

- [ ] Use caching for dependencies
- [ ] Run jobs in parallel when possible
- [ ] Use matrix builds efficiently
- [ ] Skip unnecessary steps with conditions

### Reliability

- [ ] Add retry logic for flaky steps
- [ ] Set appropriate timeouts
- [ ] Use `continue-on-error` wisely
- [ ] Add notification on failures

### Example Concurrency Control

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## CLI Reference

### GitHub CLI

| Command                      | Description        |
| ---------------------------- | ------------------ |
| `gh workflow list`           | List workflows     |
| `gh workflow run <workflow>` | Trigger workflow   |
| `gh run list`                | List workflow runs |
| `gh run view <run-id>`       | View run details   |
| `gh run watch <run-id>`      | Watch run live     |
| `gh run rerun <run-id>`      | Re-run workflow    |
| `gh secret list`             | List secrets       |
| `gh secret set <name>`       | Set secret         |

### GitLab CLI

| Command              | Description             |
| -------------------- | ----------------------- |
| `glab ci list`       | List pipelines          |
| `glab ci view <id>`  | View pipeline           |
| `glab ci retry <id>` | Retry pipeline          |
| `glab ci status`     | Current pipeline status |

## Related Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
