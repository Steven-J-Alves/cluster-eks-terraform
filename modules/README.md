# modules

Internal Terraform modules shared across the four stacks of this project.

## Overview

| Module          | Status      | Used by              | Purpose                                          |
|-----------------|-------------|----------------------|--------------------------------------------------|
| `vpc/`          | implemented | cluster              | VPC with EKS-required subnet tagging             |
| `eks/`          | implemented | cluster              | EKS cluster + managed node group + OIDC provider |
| `irsa/`         | implemented | addons/lbc, addons/externaldns | IAM role bound to a Kubernetes service account via OIDC |
| `securitygroup/`| placeholder | —                    | Reserved for future use                          |
| `acm/`          | placeholder | —                    | Reserved for future use                          |

> `securitygroup` and `acm` contain empty files. The cluster currently calls `terraform-aws-modules/security-group` directly, and ACM is managed inline in the `apps` stack.

---

## modules/vpc

Wraps [`terraform-aws-modules/vpc`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/6.7.0) and adds the subnet tags required by EKS and the AWS Load Balancer Controller.

### What it adds on top of the upstream module

- `kubernetes.io/role/elb = 1` on public subnets (external ALB placement)
- `kubernetes.io/role/internal-elb = 1` on private subnets (internal ALB placement)
- `kubernetes.io/cluster/<name> = shared` on both (EKS subnet discovery)
- `enable_dns_hostnames = true` and `map_public_ip_on_launch = true` hardcoded (required for EKS)

### Inputs

| Name                            | Type           | Required | Description                              |
|---------------------------------|----------------|----------|------------------------------------------|
| `name`                          | string         | yes      | VPC name                                 |
| `cidr`                          | string         | yes      | VPC CIDR block                           |
| `cluster_name`                  | string         | yes      | EKS cluster name (used for subnet tags)  |
| `public_subnets`                | list(string)   | yes      | Public subnet CIDRs                      |
| `private_subnets`               | list(string)   | yes      | Private subnet CIDRs                     |
| `database_subnets`              | list(string)   | no       | Database subnet CIDRs                    |
| `enable_nat_gateway`            | bool           | no       | Default: `true`                          |
| `single_nat_gateway`            | bool           | no       | Default: `true`                          |
| `create_database_subnet_group`  | bool           | no       | Default: `true`                          |
| `create_database_subnet_route_table` | bool      | no       | Default: `true`                          |
| `tags`                          | map(string)    | no       | Tags applied to all resources            |

### Outputs

`vpc_id`, `vpc_cidr_block`, `public_subnets`, `private_subnets`, `database_subnets`, `nat_public_ips`, `azs`

---

## modules/eks

Provisions an EKS cluster, a private managed node group, and an OIDC provider. All resources are created directly (no upstream module dependency).

### Resources created

| Resource                        | Details                                                        |
|---------------------------------|----------------------------------------------------------------|
| `aws_iam_role` (cluster)        | EKS control plane role with `AmazonEKSClusterPolicy`          |
| `aws_iam_role` (nodegroup)      | Node role with Worker + CNI + ECR policies                    |
| `aws_eks_cluster`               | Control plane with configurable endpoint access and logging    |
| `aws_eks_node_group`            | Private managed node group, `AL2023_x86_64_STANDARD` AMI      |
| `aws_iam_openid_connect_provider` | OIDC provider enabling IRSA for the cluster                 |

### Node group details

- AMI: `AL2023_x86_64_STANDARD` (required for EKS ≥ 1.33)
- Placement: private subnets only
- SSH key: optional via `node_group_key_name`
- Control plane logs enabled: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`

### Inputs

| Name                                 | Type         | Required | Default                |
|--------------------------------------|--------------|----------|------------------------|
| `cluster_name`                       | string       | yes      | —                      |
| `cluster_version`                    | string       | yes      | —                      |
| `public_subnet_ids`                  | list(string) | yes      | —                      |
| `private_subnet_ids`                 | list(string) | yes      | —                      |
| `cluster_endpoint_private_access`    | bool         | no       | `false`                |
| `cluster_endpoint_public_access`     | bool         | no       | `true`                 |
| `cluster_endpoint_public_access_cidrs` | list(string) | no     | `["0.0.0.0/0"]`       |
| `cluster_service_ipv4_cidr`          | string       | no       | `null`                 |
| `node_group_instance_types`          | list(string) | no       | `["t3.medium"]`        |
| `node_group_desired_size`            | number       | no       | `1`                    |
| `node_group_min_size`                | number       | no       | `1`                    |
| `node_group_max_size`                | number       | no       | `2`                    |
| `node_group_disk_size`               | number       | no       | `20`                   |
| `node_group_key_name`                | string       | no       | `""` (no SSH key)      |
| `eks_oidc_root_ca_thumbprint`        | string       | no       | valid until 2037       |
| `tags`                               | map(string)  | no       | `{}`                   |

### Outputs

`cluster_id`, `cluster_arn`, `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_version`, `cluster_iam_role_arn`, `nodegroup_iam_role_arn`, `cluster_oidc_issuer_url`, `cluster_primary_security_group_id`, `oidc_provider_arn`, `oidc_provider`, `node_group_private_status`, `node_group_private_version`

---

## modules/irsa

Creates an IAM role that can be assumed by a specific Kubernetes service account via OIDC (IAM Roles for Service Accounts). Used by both addon stacks (lbc and externaldns).

### How IRSA works

The role's trust policy uses `sts:AssumeRoleWithWebIdentity` with two conditions that pin the role to exactly one Kubernetes service account:

```
<oidc-provider>:sub = system:serviceaccount:<namespace>:<service-account>
<oidc-provider>:aud = sts.amazonaws.com
```

This means the IAM role can only be assumed by pods running as that specific service account in that specific namespace.

### Resources created

| Resource                      | Details                                     |
|-------------------------------|---------------------------------------------|
| `aws_iam_role`                | Trust policy scoped to one service account  |
| `aws_iam_policy`              | Policy from `var.policy_document`           |
| `aws_iam_role_policy_attachment` | Attaches the policy to the role          |

### Inputs

| Name               | Type   | Required | Description                                           |
|--------------------|--------|----------|-------------------------------------------------------|
| `name`             | string | yes      | Name for both the IAM role and policy                 |
| `oidc_provider_arn`| string | yes      | ARN of the cluster OIDC provider                      |
| `oidc_provider`    | string | yes      | OIDC provider URL (without `https://`)                |
| `namespace`        | string | yes      | Kubernetes namespace of the service account           |
| `service_account`  | string | yes      | Kubernetes service account name                       |
| `policy_document`  | string | yes      | JSON IAM policy to attach                             |
| `tags`             | map    | no       | `{}`                                                  |

### Outputs

`iam_role_arn`, `iam_policy_arn`

### Usage example

```hcl
module "irsa_lbc" {
  source = "../../modules/irsa"

  name              = "${local.name}-lbc"
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider
  namespace         = "kube-system"
  service_account   = "aws-load-balancer-controller"
  policy_document   = data.http.lbc_iam_policy.response_body
  tags              = local.common_tags
}
```
