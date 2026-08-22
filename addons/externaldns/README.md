# Stack 3 — ExternalDNS

Installs ExternalDNS into the EKS cluster via Helm and provisions its IAM role using IRSA. ExternalDNS watches Ingress resources and automatically creates and removes Route53 alias records pointing to the ALB.

## What this stack does

1. Creates an IAM role scoped to the `external-dns` Kubernetes service account (IRSA via OIDC)
2. Attaches an IAM policy with Route53 read + change permissions
3. Installs the ExternalDNS Helm chart configured for AWS Route53
4. Restricts DNS management to a specific domain via `domainFilters`

## Resources

| Component       | Details                                                                      |
|-----------------|------------------------------------------------------------------------------|
| IRSA role       | `modules/irsa` — bound to `default/external-dns`                            |
| IAM policy      | Route53 `ListHostedZones`, `ListResourceRecordSets`, `ChangeResourceRecordSets` |
| Helm release    | Chart `external-dns` from `https://kubernetes-sigs.github.io/external-dns/` |

## How ExternalDNS works in this project

When the `apps` stack creates a Kubernetes Ingress with this annotation:

```yaml
external-dns.alpha.kubernetes.io/hostname: eks-lab.your-domain.com
```

ExternalDNS detects the Ingress, reads the ALB DNS name assigned by the Load Balancer Controller, and creates an ALIAS A record in Route53 pointing `eks-lab.your-domain.com` to the ALB. When the Ingress is destroyed, ExternalDNS removes the record automatically (`policy: sync`).

## Helm configuration

| Parameter          | Value                     |
|--------------------|---------------------------|
| `provider`         | `aws`                     |
| `policy`           | `sync` (create + delete)  |
| `domainFilters[0]` | `your-domain.com`         |
| `serviceAccount`   | `external-dns` (via IRSA) |

## Dependency on cluster stack

This stack reads the cluster outputs from S3 remote state. The cluster must be applied before this stack.

Values consumed: `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_id`, `oidc_provider_arn`, `oidc_provider`.

## Structure

```
addons/externaldns/
├── externaldns_main/     # Terraform root
│   ├── versions.tf       # Backend (partial) + providers (aws, helm, kubernetes)
│   ├── variables.tf      # aws_region, team, environment, cluster_state_key
│   ├── locals.tf
│   ├── providers.tf      # AWS + Helm + Kubernetes providers
│   ├── data.tf           # terraform_remote_state.eks
│   ├── iam.tf            # IRSA role + policy via modules/irsa
│   ├── externaldns.tf    # Helm release
│   └── outputs.tf
└── .gitlab-ci.yml
```

## Local usage

```bash
cd addons/externaldns/externaldns_main

# Staging
terraform init   -backend-config="key=staging/externaldns/terraform.tfstate"
terraform plan   -var="cluster_state_key=staging/cluster/terraform.tfstate"
terraform apply  -var="cluster_state_key=staging/cluster/terraform.tfstate"

# Prod
terraform init   -backend-config="key=prod/externaldns/terraform.tfstate"
terraform plan   -var="cluster_state_key=prod/cluster/terraform.tfstate"
terraform apply  -var="cluster_state_key=prod/cluster/terraform.tfstate"
```

## CI guard

The CI pipeline verifies that the cluster state exists in S3 before running any Terraform command. If the cluster has not been applied yet, the job fails with a clear error message.
