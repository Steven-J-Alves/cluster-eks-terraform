# cluster-eks-terraform

Terraform project that provisions a production-ready Amazon EKS cluster and its supporting infrastructure across two environments (prod / staging). The stack is split into four independent Terraform roots, each with its own remote state and GitLab CI/CD pipeline.

## Architecture

```
VPC (public + private + database subnets, NAT Gateway)
└── EKS Cluster (1.34, AL2023 nodes, OIDC enabled)
    ├── Bastion Host (EC2, public subnet, SSM-ready)
    ├── AWS Load Balancer Controller  (Helm, IRSA)
    ├── ExternalDNS                   (Helm, IRSA, Route53)
    └── Ingress (ALB, HTTPS, SSL redirect)
        ├── /app1  → app1 NodePort Service
        ├── /app2  → app2 NodePort Service
        └── /      → app3 NodePort Service (default backend)
```

ExternalDNS automatically registers an ALB alias record in Route53 when the Ingress is created, and removes it on destroy. ACM wildcard certificate (`*.your-domain.com`) is provisioned and DNS-validated automatically by Terraform.

## Repository layout

```
cluster-eks-terraform/
├── cluster/                      # Stack 1 — VPC + EKS + Bastion
│   ├── eks_cluster_main/         # Terraform root
│   └── environments/
│       ├── prod/terraform.tfvars
│       └── staging/terraform.tfvars
│
├── addons/
│   ├── lbc/                      # Stack 2 — AWS Load Balancer Controller
│   │   └── lbc_main/             # Terraform root
│   └── externaldns/              # Stack 3 — ExternalDNS
│       └── externaldns_main/     # Terraform root
│
├── apps/                         # Stack 4 — Kubernetes workloads + Ingress + ACM
│   ├── apps_main/                # Terraform root
│   └── environments/
│       ├── prod/terraform.tfvars
│       └── staging/terraform.tfvars
│
├── modules/                      # Reusable internal modules
│   ├── vpc/                      # VPC wrapper (terraform-aws-modules/vpc 6.7.0)
│   ├── eks/                      # EKS wrapper (terraform-aws-modules/eks)
│   ├── irsa/                     # IAM Role for Service Accounts (OIDC)
│   ├── securitygroup/            # Security group wrapper (5.2.0)
│   └── acm/                      # ACM certificate + Route53 DNS validation
│
└── .gitlab-ci.yml                # Root pipeline (includes all 4 sub-pipelines)
```

## Environments

| Branch    | Environment | State prefix          | VPC CIDR      | Nodes           |
|-----------|-------------|----------------------|---------------|-----------------|
| `main`    | prod        | `prod/<stack>/`      | `10.0.0.0/16` | 2× t3.large     |
| `staging` | staging     | `staging/<stack>/`   | `10.1.0.0/16` | 1× t3.medium    |

Each environment has completely isolated AWS infrastructure and Terraform state. The `staging` branch is the integration environment; changes are merged to `main` to promote to prod.

## Remote state

| Resource       | Name                        |
|----------------|-----------------------------|
| S3 bucket      | `kk-eks-lab-tfstate`        |
| DynamoDB table | `kk-eks-lab-tfstate-lock`   |
| Region         | `us-east-1`                 |

State keys follow the pattern `<env>/<stack>/terraform.tfstate`. The `key` is never hardcoded in `versions.tf` — it is injected at `terraform init` time via `-backend-config="key=..."`, allowing the same code to target any environment.

## Provider versions

| Provider    | Version  |
|-------------|----------|
| AWS         | `~> 6.0` |
| Kubernetes  | `~> 3.0` |
| Helm        | `~> 3.0` |
| HTTP        | `~> 3.4` |
| Terraform   | `>= 1.9` |

---

## Stack 1 — cluster

**Path:** `cluster/eks_cluster_main/`

Provisions the foundational networking and compute layer.

### Resources

| Component        | Details                                                              |
|------------------|----------------------------------------------------------------------|
| VPC              | Custom CIDR, 2 AZs, public + private + database subnets             |
| NAT Gateway      | Single (staging) or multi-AZ (prod)                                  |
| EKS Control Plane| Version 1.34, public + private endpoint, OIDC provider enabled      |
| Node Group       | AL2023_x86_64_STANDARD AMI, managed, auto-scaling                   |
| Bastion Host     | EC2 in public subnet, used for kubectl access from private endpoint  |
| aws-auth ConfigMap | Managed by Terraform, grants node group access to the cluster      |

### Key outputs (consumed by addons and apps)

- `cluster_endpoint`
- `cluster_certificate_authority_data`
- `cluster_id`
- `vpc_id`
- `oidc_provider_arn`
- `oidc_provider`

### Environment differences

| Parameter           | prod              | staging           |
|---------------------|-------------------|-------------------|
| Node instance type  | `t3.large`        | `t3.medium`       |
| Desired nodes       | 2                 | 1                 |
| Max nodes           | 4                 | 2                 |
| NAT Gateways        | 2 (multi-AZ)      | 1 (single)        |
| Private endpoint    | enabled           | disabled          |

### Local usage

```bash
cd cluster/eks_cluster_main

terraform init -backend-config="key=staging/cluster/terraform.tfstate"
terraform plan  -var-file="../environments/staging/terraform.tfvars"
terraform apply -var-file="../environments/staging/terraform.tfvars"
```

---

## Stack 2 — lbc (AWS Load Balancer Controller)

**Path:** `addons/lbc/lbc_main/`

Installs the AWS Load Balancer Controller via Helm and creates its IRSA role, enabling Kubernetes Ingress resources to provision ALBs automatically.

### Resources

| Component           | Details                                                          |
|---------------------|------------------------------------------------------------------|
| IRSA role           | `modules/irsa` — scoped to `kube-system/aws-load-balancer-controller` |
| IAM policy          | AWS-managed LBC policy fetched via HTTP data source             |
| Helm release        | Chart `aws-load-balancer-controller` from `eks-charts`          |
| IngressClass        | `my-aws-ingress-class` (default for all Ingress resources)       |

### Cluster state dependency

The addon reads the cluster outputs via `terraform_remote_state`. The state key is passed at runtime:

```bash
cd addons/lbc/lbc_main

terraform init -backend-config="key=staging/lbc/terraform.tfstate"
terraform plan  -var="cluster_state_key=staging/cluster/terraform.tfstate"
terraform apply -var="cluster_state_key=staging/cluster/terraform.tfstate"
```

---

## Stack 3 — externaldns

**Path:** `addons/externaldns/externaldns_main/`

Installs ExternalDNS via Helm and creates its IRSA role, enabling automatic Route53 record management based on Ingress annotations.

### Resources

| Component     | Details                                                             |
|---------------|---------------------------------------------------------------------|
| IRSA role     | `modules/irsa` — scoped to `default/external-dns`                  |
| IAM policy    | Route53 read + change permissions                                   |
| Helm release  | Chart `external-dns` from `kubernetes-sigs.github.io/external-dns` |

### Configuration

- **Provider:** `aws`
- **Policy:** `sync` (creates and deletes records)
- **domainFilters:** restricts ExternalDNS to `your-domain.com` only

When an Ingress with `external-dns.alpha.kubernetes.io/hostname` is created, ExternalDNS registers the ALB DNS as an ALIAS record in Route53 and removes it on destroy.

### Local usage

```bash
cd addons/externaldns/externaldns_main

terraform init -backend-config="key=staging/externaldns/terraform.tfstate"
terraform plan  -var="cluster_state_key=staging/cluster/terraform.tfstate"
terraform apply -var="cluster_state_key=staging/cluster/terraform.tfstate"
```

---

## Stack 4 — apps

**Path:** `apps/apps_main/`

Deploys Kubernetes workloads and the ALB Ingress with HTTPS. All application configuration is driven by a single `apps` variable — adding a new application requires only a new entry in `terraform.tfvars`.

### Resources

| Component                | Details                                                   |
|--------------------------|-----------------------------------------------------------|
| Deployments              | One per entry in `var.apps` (via `for_each`)              |
| NodePort Services        | One per entry in `var.apps` (via `for_each`)              |
| Ingress (ALB)            | Dynamic path rules from `var.apps[*].ingress_path`        |
| ACM Certificate          | Wildcard `*.your-domain.com`, DNS validation via Route53  |
| Route53 validation records | Created and managed by Terraform                        |

### apps variable

Each application is defined as a map entry:

```hcl
apps = {
  app1 = {
    image        = "your-registry/app1:1.0.0"
    replicas     = 1
    healthcheck  = "/app1/index.html"
    ingress_path = "/app1"           # routed path on the ALB
  }
  app3 = {
    image       = "your-registry/app3:1.0.0"
    replicas    = 1
    healthcheck = "/index.html"
    # no ingress_path = default backend (catches all unmatched requests)
  }
}
```

Apps without `ingress_path` become the Ingress default backend. Apps with `ingress_path` are added as path-based routing rules.

### Ingress annotations

| Annotation                                  | Value                              |
|---------------------------------------------|------------------------------------|
| `alb.ingress.kubernetes.io/scheme`          | `internet-facing`                  |
| `alb.ingress.kubernetes.io/listen-ports`    | `[{"HTTPS":443},{"HTTP":80}]`      |
| `alb.ingress.kubernetes.io/ssl-redirect`    | `443`                              |
| `alb.ingress.kubernetes.io/load-balancer-name` | `<team>-<env>-eks-lab`          |
| `external-dns.alpha.kubernetes.io/hostname` | `eks-lab.your-domain.com`          |

### Local usage

```bash
cd apps/apps_main

terraform init -backend-config="key=staging/apps/terraform.tfstate"
terraform plan  -var-file="../environments/staging/terraform.tfvars" \
                -var="cluster_state_key=staging/cluster/terraform.tfstate"
terraform apply -var-file="../environments/staging/terraform.tfvars" \
                -var="cluster_state_key=staging/cluster/terraform.tfstate"
```

---

## CI/CD

### Pipeline structure

Each stack has its own `.gitlab-ci.yml` included by the root pipeline:

```
.gitlab-ci.yml
├── cluster/.gitlab-ci.yml
├── addons/lbc/.gitlab-ci.yml
├── addons/externaldns/.gitlab-ci.yml
└── apps/.gitlab-ci.yml
```

### Stages and jobs

```
validate → plan → apply (manual) → destroy (manual)
```

Each branch/environment pair has its own set of jobs:

| Job pattern                  | Triggers on                      |
|------------------------------|----------------------------------|
| `cluster:validate/plan`      | push to `main`, changes in `cluster/**` or `modules/**` |
| `cluster:apply`              | same, manual button              |
| `cluster:staging:validate`   | push to `staging`, same filters  |
| `apps:staging:validate/plan` | push to `staging`, changes in `apps/**` |

### Runner

All jobs use `tags: [docker]` to target `vps-native-runner`, a shell executor with Docker socket access. Terraform runs inside a `hashicorp/terraform:1.9` container via `docker run`, keeping the host clean.

### Deploy order

```
cluster:apply → lbc:apply → externaldns:apply → apps:apply
```

The `lbc` and `externaldns` pipelines include a guard that checks whether the cluster state exists in S3 before running — preventing accidental deploys into a non-existent cluster.

### GitFlow

```
feature/* ──► staging (validate + plan auto, apply manual)
staging   ──► main    (promote to prod via MR)
```

---

## Modules

| Module          | Source                              | Purpose                                    |
|-----------------|-------------------------------------|--------------------------------------------|
| `modules/vpc`   | `terraform-aws-modules/vpc` 6.7.0   | VPC with EKS subnet tagging                |
| `modules/eks`   | `terraform-aws-modules/eks`         | EKS cluster + managed node group + OIDC    |
| `modules/irsa`  | internal                            | IAM Role + Policy bound to a K8s service account via OIDC |
| `modules/securitygroup` | `terraform-aws-modules/security-group` 5.2.0 | Bastion security group     |
| `modules/acm`   | internal                            | ACM certificate + Route53 DNS validation   |

---

## Prerequisites

- AWS CLI configured with a named profile (`steven-prod` or equivalent)
- Terraform >= 1.9
- `kubectl` configured after cluster apply:
  ```bash
  aws eks update-kubeconfig --region us-east-1 --name <cluster-name> --profile <profile>
  ```
- S3 bucket and DynamoDB table for remote state (create once, reuse across environments)
- Route53 hosted zone for your domain
- EC2 key pair (`kk-eks-lab-key`) for Bastion SSH access

---

## Cost awareness

| Resource         | Approx. cost                    |
|------------------|---------------------------------|
| EKS control plane | ~$0.10/h per cluster           |
| NAT Gateway      | ~$0.045/h + data transfer       |
| EC2 nodes        | depends on instance type        |
| ALB              | ~$0.008/h + LCU charges         |

Destroy resources after validation to avoid idle charges. Destroy in reverse order:

```bash
# apps → externaldns → lbc → cluster
terraform -chdir=apps/apps_main         destroy -var-file="../environments/staging/terraform.tfvars" -auto-approve
terraform -chdir=addons/externaldns/externaldns_main destroy -auto-approve
terraform -chdir=addons/lbc/lbc_main   destroy -auto-approve
terraform -chdir=cluster/eks_cluster_main destroy -var-file="../environments/staging/terraform.tfvars" -auto-approve
```
