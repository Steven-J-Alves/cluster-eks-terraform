# Stack 4 — apps

Deploys Kubernetes workloads, an ALB Ingress with HTTPS, and an ACM wildcard certificate with automatic DNS validation. All applications are defined through a single `apps` variable — no new Terraform files are needed to add or remove an application.

## What this stack does

1. Provisions an ACM wildcard certificate for the domain and validates it via Route53 DNS records
2. For each entry in `var.apps`: creates a Deployment and a NodePort Service
3. Creates a single Ingress resource that routes traffic based on `ingress_path` per app
4. The app without an `ingress_path` becomes the Ingress default backend
5. ExternalDNS (deployed in stack 3) automatically registers the ALB DNS in Route53

## Resources

| Component               | Details                                                        |
|-------------------------|----------------------------------------------------------------|
| ACM certificate         | Wildcard `*.your-domain.com`, DNS validation via Route53       |
| Route53 validation records | Created and managed by Terraform                            |
| Kubernetes Deployments  | One per app entry (`for_each = var.apps`)                      |
| Kubernetes NodePort Services | One per app entry (`for_each = var.apps`)                |
| Kubernetes Ingress (ALB) | Single resource, dynamic path rules, HTTPS redirect          |

## Adding or removing an application

Only `terraform.tfvars` needs to change. No Terraform files are modified.

```hcl
# environments/prod/terraform.tfvars

apps = {
  app1 = {
    image        = "your-registry/app1:2.0.0"
    replicas     = 2
    healthcheck  = "/app1/index.html"
    ingress_path = "/app1"
  }
  app2 = {
    image        = "your-registry/app2:1.0.0"
    replicas     = 1
    healthcheck  = "/app2/index.html"
    ingress_path = "/app2"
  }
  app3 = {
    image       = "your-registry/app3:1.0.0"
    replicas    = 1
    healthcheck = "/index.html"
    # no ingress_path = this app is the default backend
  }
}
```

- Apps with `ingress_path` are added as path-based routing rules on the ALB
- The app without `ingress_path` (controlled by `var.default_backend_app`) catches all unmatched requests

## Ingress configuration

| Annotation                                    | Value                           |
|-----------------------------------------------|---------------------------------|
| `alb.ingress.kubernetes.io/scheme`            | `internet-facing`               |
| `alb.ingress.kubernetes.io/listen-ports`      | `[{"HTTPS":443},{"HTTP":80}]`   |
| `alb.ingress.kubernetes.io/ssl-redirect`      | `443`                           |
| `alb.ingress.kubernetes.io/load-balancer-name` | `<team>-<env>-eks-lab`         |
| `alb.ingress.kubernetes.io/certificate-arn`   | from `aws_acm_certificate_validation` |
| `external-dns.alpha.kubernetes.io/hostname`   | `var.app_hostname`              |

## Environment differences

| Parameter      | prod                          | staging                          |
|----------------|-------------------------------|----------------------------------|
| `environment`  | `prod`                        | `staging`                        |
| `app_hostname` | `eks-lab.your-domain.com`     | `eks-lab-staging.your-domain.com` |
| `cluster_state_key` | `prod/cluster/terraform.tfstate` | `staging/cluster/terraform.tfstate` |
| ALB name       | `kk-prod-eks-lab`             | `kk-staging-eks-lab`             |

## Structure

```
apps/
├── apps_main/              # Terraform root
│   ├── versions.tf         # Backend (partial) + providers (aws, kubernetes)
│   ├── variables.tf        # All variables including the apps map
│   ├── locals.tf           # lb_name, routed_apps (apps with ingress_path)
│   ├── providers.tf        # AWS + Kubernetes providers (from cluster remote state)
│   ├── remote-state.tf     # terraform_remote_state.eks
│   ├── acm.tf              # ACM cert + Route53 DNS validation records
│   ├── deployments.tf      # kubernetes_deployment_v1 (for_each = var.apps)
│   ├── services.tf         # kubernetes_service_v1 NodePort (for_each = var.apps)
│   └── ingress.tf          # kubernetes_ingress_v1 with dynamic path blocks
└── environments/
    ├── prod/terraform.tfvars
    └── staging/terraform.tfvars
```

## Local usage

```bash
cd apps/apps_main

# Staging
terraform init   -backend-config="key=staging/apps/terraform.tfstate"
terraform plan   -var-file="../environments/staging/terraform.tfvars" \
                 -var="cluster_state_key=staging/cluster/terraform.tfstate"
terraform apply  -var-file="../environments/staging/terraform.tfvars" \
                 -var="cluster_state_key=staging/cluster/terraform.tfstate"

# Prod
terraform init   -backend-config="key=prod/apps/terraform.tfstate"
terraform plan   -var-file="../environments/prod/terraform.tfvars" \
                 -var="cluster_state_key=prod/cluster/terraform.tfstate"
terraform apply  -var-file="../environments/prod/terraform.tfvars" \
                 -var="cluster_state_key=prod/cluster/terraform.tfstate"
```

## Validation after apply

```bash
# Ingress provisioned and ALB address assigned
kubectl get ingress -A

# All pods running
kubectl get pods -A

# DNS resolving (ExternalDNS takes ~30s to register)
nslookup eks-lab.your-domain.com

# HTTPS working
curl -L https://eks-lab.your-domain.com/app1/index.html
curl -L https://eks-lab.your-domain.com/app2/index.html
curl -L https://eks-lab.your-domain.com/
```

## Destroy

Destroy this stack before destroying externaldns, lbc, or cluster.

```bash
terraform destroy -var-file="../environments/staging/terraform.tfvars" \
                  -var="cluster_state_key=staging/cluster/terraform.tfstate"
```

> ExternalDNS will automatically remove the Route53 record when the Ingress is deleted.
