# Stack 1 — cluster

Provisions the foundational networking and compute layer: VPC, EKS cluster, managed node group, and a Bastion host for private access.

## Resources

| Component          | Details                                                                 |
|--------------------|-------------------------------------------------------------------------|
| VPC                | Custom CIDR, 2 AZs, public + private + database subnets, NAT Gateway   |
| EKS Control Plane  | Version 1.34, public + private endpoint configurable, OIDC enabled      |
| Managed Node Group | AL2023_x86_64_STANDARD AMI, auto-scaling, configurable instance type    |
| Bastion Host       | EC2 in public subnet for kubectl access when private endpoint is active |
| aws-auth ConfigMap | Managed by Terraform, grants node group access to the cluster           |

## Modules used

| Module              | Source                                     | Purpose                              |
|---------------------|--------------------------------------------|--------------------------------------|
| `modules/vpc`       | `terraform-aws-modules/vpc` 6.7.0          | VPC with EKS subnet tagging          |
| `modules/eks`       | `terraform-aws-modules/eks`                | EKS cluster + node group + OIDC      |
| `modules/securitygroup` | `terraform-aws-modules/security-group` 5.2.0 | Bastion security group           |

## Outputs consumed by addons

The addons and apps stacks read these values from remote state:

| Output                            | Used by              |
|-----------------------------------|----------------------|
| `cluster_endpoint`                | lbc, externaldns, apps |
| `cluster_certificate_authority_data` | lbc, externaldns, apps |
| `cluster_id`                      | lbc, externaldns, apps |
| `vpc_id`                          | lbc                  |
| `oidc_provider_arn`               | lbc, externaldns     |
| `oidc_provider`                   | lbc, externaldns     |

## Environment differences

| Parameter           | prod                   | staging              |
|---------------------|------------------------|----------------------|
| VPC CIDR            | `10.0.0.0/16`          | `10.1.0.0/16`        |
| Node instance type  | `t3.large`             | `t3.medium`          |
| Desired nodes       | 2                      | 1                    |
| Max nodes           | 4                      | 2                    |
| Disk per node       | 30 GB                  | 20 GB                |
| NAT Gateways        | 2 (multi-AZ)           | 1 (single)           |
| Private endpoint    | enabled                | disabled             |

## Structure

```
cluster/
├── eks_cluster_main/         # Terraform root
│   ├── versions.tf           # Backend (partial) + providers
│   ├── variables.tf          # General variables (region, team, environment)
│   ├── locals.tf             # name, tags, eks_cluster_name
│   ├── vpc.tf                # VPC module call
│   ├── vpc-variables.tf      # VPC-specific variables
│   ├── vpc-outputs.tf
│   ├── eks.tf                # EKS module call
│   ├── eks-variables.tf      # EKS-specific variables
│   ├── eks-outputs.tf
│   ├── bastion.tf            # EC2 instance
│   ├── bastion-sg.tf         # Security group
│   ├── bastion-eip.tf        # Elastic IP
│   ├── bastion-variables.tf
│   ├── bastion-outputs.tf
│   ├── configmap.tf          # aws-auth ConfigMap
│   ├── data.tf               # aws_caller_identity, aws_region
│   └── providers.tf          # Kubernetes provider (for aws-auth)
└── environments/
    ├── prod/terraform.tfvars
    └── staging/terraform.tfvars
```

## Local usage

```bash
cd cluster/eks_cluster_main

# Staging
terraform init   -backend-config="key=staging/cluster/terraform.tfstate"
terraform plan   -var-file="../environments/staging/terraform.tfvars"
terraform apply  -var-file="../environments/staging/terraform.tfvars"

# Prod
terraform init   -backend-config="key=prod/cluster/terraform.tfstate"
terraform plan   -var-file="../environments/prod/terraform.tfvars"
terraform apply  -var-file="../environments/prod/terraform.tfvars"
```

After apply, configure kubectl:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name <team>-<env>-eks \
  --profile <aws-profile>
```

## Destroy

```bash
terraform destroy -var-file="../environments/staging/terraform.tfvars"
```

> Destroy apps, externaldns, and lbc stacks before destroying the cluster.
