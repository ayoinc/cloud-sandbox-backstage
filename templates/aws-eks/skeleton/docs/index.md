# ${{ values.name }}

${{ values.description }}

## Overview

This EKS cluster provides a production-ready Kubernetes platform for the **${{ values.environment }}** environment in **${{ values.region }}**. The infrastructure is managed by Terraform and includes:

- Fully managed Kubernetes control plane with automatic upgrades
- Managed node groups with auto-scaling capabilities
- IAM Roles for Service Accounts (IRSA) for secure pod-level AWS access
- OIDC provider for workload identity federation
- Cluster Autoscaler and AWS Load Balancer Controller IRSA roles pre-configured
- CloudWatch logging for control plane components
- Private networking with configurable public/private API endpoint access

```d2
direction: right

title: {
  label: AWS EKS Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

internet: Internet {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

aws: AWS Cloud (${{ values.region }}) {
  style.fill: "#FAFAFA"
  style.stroke: "#232F3E"

  vpc: VPC {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    public: Public Subnets {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"

      alb: Application Load Balancer {
        shape: hexagon
        style.fill: "#BBDEFB"
      }
      nat: NAT Gateway {
        shape: hexagon
        style.fill: "#C8E6C9"
      }
    }

    private: Private Subnets {
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"

      eks: EKS Cluster {
        style.fill: "#FFF8E1"
        style.stroke: "#FF8F00"

        control: Control Plane {
          shape: cylinder
          style.fill: "#FFE0B2"
          style.stroke: "#F57C00"
          label: "API Server\nController Manager\netcd\nScheduler"
        }

        nodes: Managed Node Group {
          style.fill: "#E1F5FE"
          style.stroke: "#0288D1"

          node1: Worker Node 1 {
            shape: rectangle
            style.fill: "#B3E5FC"
          }
          node2: Worker Node 2 {
            shape: rectangle
            style.fill: "#B3E5FC"
          }
          node3: Worker Node N {
            shape: rectangle
            style.fill: "#B3E5FC"
            style.stroke-dash: 3
          }
        }
      }
    }
  }

  iam: IAM {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"

    cluster_role: Cluster Role
    node_role: Node Role
    oidc: OIDC Provider {
      shape: hexagon
    }
    irsa: IRSA Roles {
      autoscaler: Cluster Autoscaler
      lb_controller: LB Controller
    }
  }

  cloudwatch: CloudWatch Logs {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  ecr: ECR {
    shape: cylinder
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }
}

internet -> aws.vpc.public.alb: HTTPS
aws.vpc.public.alb -> aws.vpc.private.eks.nodes: ingress
aws.vpc.private.eks.nodes -> aws.vpc.public.nat: outbound
aws.vpc.public.nat -> internet
aws.vpc.private.eks.control -> aws.cloudwatch: logs
aws.vpc.private.eks.nodes -> aws.ecr: pull images
aws.iam.oidc -> aws.iam.irsa: federation
aws.iam.cluster_role -> aws.vpc.private.eks.control
aws.iam.node_role -> aws.vpc.private.eks.nodes
```

---

## Configuration Summary

| Setting                  | Value                                |
| ------------------------ | ------------------------------------ |
| Cluster Name             | `${{ values.name }}-${{ values.environment }}` |
| Kubernetes Version       | `${{ values.kubernetesVersion }}`    |
| Region                   | `${{ values.region }}`               |
| Environment              | `${{ values.environment }}`          |
| Node Instance Type       | `${{ values.nodeInstanceType }}`     |
| Node Capacity Type       | `ON_DEMAND`                          |
| Desired Nodes            | ${{ values.nodeDesiredSize }}        |
| Min Nodes                | ${{ values.nodeMinSize }}            |
| Max Nodes                | ${{ values.nodeMaxSize }}            |
| Node Disk Size           | `50 GB`                              |
| Private Endpoint Access  | `true`                               |
| Public Endpoint Access   | `true` (dev/staging), `false` (prod) |
| Cluster Autoscaler IRSA  | Enabled                              |
| AWS LB Controller IRSA   | Enabled                              |

---

## Cluster Features

| Feature                       | Description                                                    |
| ----------------------------- | -------------------------------------------------------------- |
| **Managed Node Groups**       | Auto-scaling worker nodes with automated OS updates            |
| **IRSA**                      | IAM Roles for Service Accounts for secure AWS API access       |
| **Cluster Autoscaler Ready**  | Pre-configured IRSA role for automatic node scaling            |
| **ALB Controller Ready**      | Pre-configured IRSA role for AWS Load Balancer Controller      |
| **Private Networking**        | Nodes run exclusively in private subnets                       |
| **Control Plane Logging**     | All control plane logs sent to CloudWatch                      |
| **SSM Access**                | Nodes have SSM agent for secure shell access without SSH keys  |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Preflight Checks**: AWS connectivity and prerequisites validation
- **Validation**: Format checking, TFLint, Terraform validation
- **Testing**: Terraform native tests for configuration validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Drift Detection**: Scheduled checks for configuration drift

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

preflight: Preflight {
  style.fill: "#ECEFF1"
  style.stroke: "#607D8B"
  label: "AWS Auth\nState Backend\nEKS Permissions"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nTFLint\nValidate"
}

test: Test {
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Terraform Test\nUnit Tests"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Generate Plan\nCost Estimate"
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

apply: Apply {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Deploy\nEKS Cluster"
}

pr -> preflight -> validate -> test -> security -> plan -> review -> apply
```

### Pipeline Stages

| Stage     | Trigger           | Actions                                              |
| --------- | ----------------- | ---------------------------------------------------- |
| Preflight | All               | AWS OIDC auth, state backend verification, EKS perms |
| Validate  | All               | terraform fmt, tflint, terraform validate            |
| Test      | All               | terraform test for configuration validation          |
| Security  | All               | tfsec, Checkov, Trivy scanning                       |
| Cost      | Pull Request      | Infracost analysis and PR comment                    |
| Plan      | All               | terraform plan for each environment                  |
| Apply     | Manual Dispatch   | terraform apply with environment approval            |
| Destroy   | Manual Dispatch   | terraform destroy with confirmation                  |
| Drift     | Scheduled (daily) | Check for configuration drift                        |

---

## Prerequisites

### 1. AWS Account Setup

#### Create OIDC Identity Provider

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with AWS.

```bash
# Create the OIDC provider (one-time setup per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role for GitHub Actions

Create a role with the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/${{ values.name }}:*"
        }
      }
    }
  ]
}
```

#### Required IAM Permissions for EKS

Attach a policy with these permissions to the GitHub Actions role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSClusterManagement",
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DeleteCluster",
        "eks:DescribeCluster",
        "eks:UpdateClusterConfig",
        "eks:UpdateClusterVersion",
        "eks:ListClusters",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:CreateNodegroup",
        "eks:DeleteNodegroup",
        "eks:DescribeNodegroup",
        "eks:UpdateNodegroupConfig",
        "eks:UpdateNodegroupVersion",
        "eks:ListNodegroups",
        "eks:CreateAddon",
        "eks:DeleteAddon",
        "eks:DescribeAddon",
        "eks:UpdateAddon",
        "eks:ListAddons"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2Permissions",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:DescribeInstances",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "ec2:DeleteLaunchTemplate"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:CreateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviders",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile"
      ],
      "Resource": [
        "arn:aws:iam::*:role/${{ values.name }}-*",
        "arn:aws:iam::*:oidc-provider/oidc.eks.*.amazonaws.com/*",
        "arn:aws:iam::*:instance-profile/${{ values.name }}-*"
      ]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "logs:ListTagsLogGroup"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/eks/${{ values.name }}-*"
    },
    {
      "Sid": "AutoScaling",
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:CreateOrUpdateTags",
        "autoscaling:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR_STATE_BUCKET",
        "arn:aws:s3:::YOUR_STATE_BUCKET/*"
      ]
    },
    {
      "Sid": "StateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

#### Create Terraform State Backend

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region ${{ values.region }}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. VPC Requirements

This EKS cluster requires an existing VPC with:

- **Private subnets** across multiple availability zones (for node groups)
- **NAT Gateway** for outbound internet access from private subnets
- **Subnet tags** for Kubernetes integration:
  - `kubernetes.io/cluster/${{ values.name }}-${{ values.environment }}: shared`
  - `kubernetes.io/role/internal-elb: 1` (for private subnets)
  - `kubernetes.io/role/elb: 1` (for public subnets)

Use the [aws-vpc](/docs/default/template/aws-vpc) template to create a compatible VPC.

### 3. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                | Description                                 | Example                                              |
| --------------------- | ------------------------------------------- | ---------------------------------------------------- |
| `AWS_ROLE_ARN`        | IAM role ARN for OIDC authentication        | `arn:aws:iam::123456789012:role/github-actions-role` |
| `TF_STATE_BUCKET`     | S3 bucket name for Terraform state          | `my-terraform-state-bucket`                          |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking (optional) | `terraform-state-lock`                               |
| `INFRACOST_API_KEY`   | API key for cost estimation (optional)      | `ico-xxxxxxxx`                                       |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description          | Default               |
| ------------ | -------------------- | --------------------- |
| `AWS_REGION` | Default AWS region   | `${{ values.region }}`|

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules                                     | Reviewers                |
| ----------- | ---------------------------------------------------- | ------------------------ |
| `dev`       | None                                                 | -                        |
| `staging`   | Required reviewers (optional)                        | Team leads               |
| `prod`      | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Initialize Terraform
terraform init

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate AWS credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Configuring kubectl Access

After the cluster is deployed, configure kubectl to access it:

```bash
# Update kubeconfig for the cluster
aws eks update-kubeconfig \
  --region ${{ values.region }} \
  --name ${{ values.name }}-${{ values.environment }}

# Verify connection
kubectl get nodes
kubectl get namespaces
kubectl cluster-info
```

### Deploying Applications

```bash
# Create a namespace for your application
kubectl create namespace my-app

# Deploy using a manifest
kubectl apply -f deployment.yaml -n my-app

# Deploy using Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/nginx -n my-app
```

### Installing Cluster Add-ons

#### Cluster Autoscaler

The IRSA role for Cluster Autoscaler is pre-configured. Install using Helm:

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler

helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=${{ values.name }}-${{ values.environment }} \
  --set awsRegion=${{ values.region }} \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw cluster_autoscaler_role_arn)
```

#### AWS Load Balancer Controller

The IRSA role for AWS Load Balancer Controller is pre-configured. Install using Helm:

```bash
helm repo add eks https://aws.github.io/eks-charts

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=${{ values.name }}-${{ values.environment }} \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw aws_lb_controller_role_arn)
```

### Running the Pipeline

#### Automatic Triggers

| Trigger      | Actions                                              |
| ------------ | ---------------------------------------------------- |
| Pull Request | Preflight, Validate, Test, Security Scan, Plan, Cost |
| Push to main | Preflight, Validate, Test, Security Scan, Plan (all) |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **AWS EKS Infrastructure** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, or `destroy`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

---

## Security Scanning

The pipeline includes three security scanning tools:

| Tool        | Purpose                                                   | Documentation                        |
| ----------- | --------------------------------------------------------- | ------------------------------------ |
| **tfsec**   | Static analysis for Terraform security misconfigurations  | [tfsec.dev](https://tfsec.dev)       |
| **Checkov** | Policy-as-code for infrastructure security and compliance | [checkov.io](https://www.checkov.io) |
| **Trivy**   | Comprehensive vulnerability scanner for IaC               | [trivy.dev](https://trivy.dev)       |

Results are uploaded to the GitHub **Security** tab as SARIF reports.

### Common Security Findings

| Finding                                 | Resolution                                                     |
| --------------------------------------- | -------------------------------------------------------------- |
| EKS public endpoint enabled             | Restricted to specific CIDRs or disabled in production         |
| Node group has public IP                | Nodes are deployed in private subnets (no public IPs)          |
| Missing encryption for secrets          | Enable EKS secrets encryption with AWS KMS                     |
| Cluster logging not enabled             | Control plane logging is enabled in this template              |
| Overly permissive security group rules  | Review and restrict egress rules as needed                     |

### EKS-Specific Security Best Practices

- **Enable Secrets Encryption**: Use AWS KMS to encrypt Kubernetes secrets at rest
- **Private API Endpoint**: Disable public endpoint for production clusters
- **Network Policies**: Implement Kubernetes network policies for pod-to-pod traffic control
- **Pod Security Standards**: Apply Pod Security Admission for workload security
- **IRSA**: Use IAM Roles for Service Accounts instead of node-level IAM roles

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource                          | Monthly Cost (USD)          |
| --------------------------------- | --------------------------- |
| EKS Control Plane                 | ~$73 (fixed)                |
| EC2 Nodes (${{ values.nodeInstanceType }} x ${{ values.nodeDesiredSize }}) | Variable based on instance type |
| NAT Gateway Data Processing       | Variable (based on traffic) |
| CloudWatch Logs                   | Variable (based on volume)  |
| **Total Base Cost**               | ~$150-300/month (estimated) |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                            | Description                              |
| --------------------------------- | ---------------------------------------- |
| `cluster_id`                      | The ID of the EKS cluster                |
| `cluster_arn`                     | The ARN of the EKS cluster               |
| `cluster_name`                    | The name of the EKS cluster              |
| `cluster_endpoint`                | The endpoint for the EKS API server      |
| `cluster_version`                 | The Kubernetes version of the cluster    |
| `cluster_certificate_authority_data` | Base64 encoded CA certificate (sensitive) |
| `cluster_security_group_id`       | Security group for the control plane     |
| `cluster_primary_security_group_id` | Primary security group created by EKS   |
| `cluster_iam_role_arn`            | ARN of the cluster IAM role              |
| `node_group_iam_role_arn`         | ARN of the node group IAM role           |
| `oidc_provider_arn`               | ARN of the OIDC provider for IRSA        |
| `oidc_issuer`                     | The OIDC issuer URL                      |
| `node_group_id`                   | EKS node group ID                        |
| `node_group_arn`                  | ARN of the EKS node group                |
| `cluster_autoscaler_role_arn`     | IAM role ARN for Cluster Autoscaler      |
| `aws_lb_controller_role_arn`      | IAM role ARN for AWS LB Controller       |
| `kubeconfig_command`              | AWS CLI command to update kubeconfig     |

Access outputs via:

```bash
# Get single output
terraform output cluster_endpoint

# Get output as JSON
terraform output -json

# Get kubeconfig command
terraform output kubeconfig_command
```

---

## Troubleshooting

### Authentication Issues

**Error: No valid credential sources found**

```
Error: configuring Terraform AWS Provider: no valid credential sources for S3 Backend found.
```

**Resolution:**

1. Verify `AWS_ROLE_ARN` secret is configured correctly
2. Check OIDC provider is set up in AWS IAM
3. Ensure trust policy includes your repository: `repo:YOUR_ORG/${{ values.name }}:*`
4. Verify the IAM role has the required EKS permissions

### Cluster Creation Issues

**Error: Error creating EKS Cluster: ResourceInUseException**

```
Error: creating EKS Cluster: ResourceInUseException: Cluster already exists
```

**Resolution:**

1. Check if a cluster with the same name already exists
2. Use Terraform import if the cluster was created outside Terraform
3. Choose a different cluster name

**Error: Cannot create cluster in the specified subnets**

```
Error: creating EKS Cluster: InvalidParameterException: Cannot create cluster in the specified subnets
```

**Resolution:**

1. Ensure subnets are in at least 2 different availability zones
2. Verify subnets have the required Kubernetes tags
3. Check subnets have available IP addresses

### Node Group Issues

**Error: Nodes not joining cluster**

**Resolution:**

1. Verify the node IAM role has the required policies attached
2. Check security group allows communication between nodes and control plane
3. Ensure nodes can reach the EKS API endpoint (NAT Gateway for private subnets)
4. Check node group status in AWS Console for detailed error messages

```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name ${{ values.name }}-${{ values.environment }} \
  --nodegroup-name ${{ values.name }}-${{ values.environment }}-nodes
```

### kubectl Access Issues

**Error: Unable to connect to the server**

```
Unable to connect to the server: dial tcp: lookup xxx.yl4.us-east-1.eks.amazonaws.com: no such host
```

**Resolution:**

1. Ensure your kubeconfig is up to date:
   ```bash
   aws eks update-kubeconfig --name ${{ values.name }}-${{ values.environment }} --region ${{ values.region }}
   ```
2. Check if the cluster API endpoint is accessible from your network
3. For private endpoints, connect via VPN or bastion host

**Error: Unauthorized**

```
error: You must be logged in to the server (Unauthorized)
```

**Resolution:**

1. Verify your AWS credentials are valid and not expired
2. Check if your IAM user/role is mapped in the aws-auth ConfigMap
3. Ensure your IAM entity has the required EKS permissions

### State Backend Issues

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually remove the lock from DynamoDB:
   ```bash
   aws dynamodb delete-item \
     --table-name terraform-state-lock \
     --key '{"LockID":{"S":"your-bucket/path/terraform.tfstate"}}'
   ```

### Pipeline Failures

**Security scan failing**

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

**Terraform test failures**

Review test output and fix configuration issues:

```bash
# Run tests locally
terraform test -verbose
```

---

## Related Templates

| Template                                        | Description                                         |
| ----------------------------------------------- | --------------------------------------------------- |
| [aws-vpc](/docs/default/template/aws-vpc)       | Amazon VPC (required for EKS deployment)            |
| [aws-rds](/docs/default/template/aws-rds)       | Amazon RDS database (for application databases)     |
| [aws-lambda](/docs/default/template/aws-lambda) | AWS Lambda serverless function                      |
| [aws-ecr](/docs/default/template/aws-ecr)       | Amazon ECR container registry                       |
| [helm-chart](/docs/default/template/helm-chart) | Helm chart deployment template                      |

---

## References

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS EKS Module](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## Owner

This resource is owned by **${{ values.owner }}**.
