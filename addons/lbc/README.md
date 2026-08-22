# Stack 2 — AWS Load Balancer Controller

Installs the AWS Load Balancer Controller (LBC) into the EKS cluster via Helm and provisions its IAM role using IRSA (IAM Roles for Service Accounts). The LBC is required before any Ingress resource can provision an ALB.

## What this stack does

1. Creates an IAM role scoped to the `aws-load-balancer-controller` Kubernetes service account (IRSA via OIDC)
2. Attaches the official AWS-managed LBC IAM policy (fetched at plan time via HTTP)
3. Installs the Helm chart into `kube-system`
4. Creates the `IngressClass` resource (`my-aws-ingress-class`) used by all Ingress resources in this project

## Resources

| Component       | Details                                                                  |
|-----------------|--------------------------------------------------------------------------|
| IRSA role       | `modules/irsa` — bound to `kube-system/aws-load-balancer-controller`    |
| IAM policy      | AWS-managed LBC policy, fetched via `http` data source at plan time      |
| Helm release    | Chart `aws-load-balancer-controller` from `https://aws.github.io/eks-charts` |
| IngressClass    | `my-aws-ingress-class` (set as default for the cluster)                  |

## Dependency on cluster stack

This stack reads the cluster outputs from S3 remote state. The cluster must be applied before this stack.

```hcl
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "kk-eks-lab-tfstate"
    key    = var.cluster_state_key   # injected at init
    region = var.aws_region
  }
}
```

Values consumed: `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_id`, `vpc_id`, `oidc_provider_arn`, `oidc_provider`.

## Structure

```
addons/lbc/
├── lbc_main/             # Terraform root
│   ├── versions.tf       # Backend (partial) + providers (aws, helm, kubernetes, http)
│   ├── variables.tf      # aws_region, team, environment, cluster_state_key
│   ├── locals.tf
│   ├── providers.tf      # AWS provider
│   ├── kubernetes-provider.tf  # Kubernetes provider (from cluster remote state)
│   ├── data.tf           # terraform_remote_state.eks
│   ├── lbc-data.tf       # HTTP data source for IAM policy JSON
│   ├── iam.tf            # IRSA role + policy via modules/irsa
│   ├── lbc.tf            # Helm release
│   ├── ingress-class.tf  # IngressClass resource
│   └── outputs.tf
└── .gitlab-ci.yml
```

## Local usage

```bash
cd addons/lbc/lbc_main

# Staging
terraform init   -backend-config="key=staging/lbc/terraform.tfstate"
terraform plan   -var="cluster_state_key=staging/cluster/terraform.tfstate"
terraform apply  -var="cluster_state_key=staging/cluster/terraform.tfstate"

# Prod
terraform init   -backend-config="key=prod/lbc/terraform.tfstate"
terraform plan   -var="cluster_state_key=prod/cluster/terraform.tfstate"
terraform apply  -var="cluster_state_key=prod/cluster/terraform.tfstate"
```

## CI guard

The CI pipeline verifies that the cluster state exists in S3 before running any Terraform command:

```bash
aws s3 ls "s3://kk-eks-lab-tfstate/$CLUSTER_STATE_KEY"
# exits 1 if not found → pipeline fails with a clear error message
```
