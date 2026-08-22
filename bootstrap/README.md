# bootstrap/ — Remote State Backend

Terraform stack that provisions the **S3 bucket and DynamoDB lock table** used by every other stack in this repo. Must be applied **once**, before anything else.

---

## What it creates

### S3 Bucket — `kk-eks-lab-tfstate`

- **Versioning:** enabled (allows state rollback)
- **Encryption:** AES-256 server-side encryption
- **Public access:** fully blocked

Used as the remote backend by `cluster/`, `addons/lbc/`, `addons/externaldns/`, and `apps/` stacks.

### DynamoDB Lock Table — `kk-eks-lab-tfstate-lock`

Single shared table with `PAY_PER_REQUEST` billing. All stacks use the same table — state keys are namespaced by environment and stack:

| Stack          | Prod state key                       | Staging state key                       |
|----------------|--------------------------------------|-----------------------------------------|
| cluster        | `prod/cluster/terraform.tfstate`     | `staging/cluster/terraform.tfstate`     |
| addons/lbc     | `prod/lbc/terraform.tfstate`         | `staging/lbc/terraform.tfstate`         |
| addons/externaldns | `prod/externaldns/terraform.tfstate` | `staging/externaldns/terraform.tfstate` |
| apps           | `prod/apps/terraform.tfstate`        | `staging/apps/terraform.tfstate`        |

### IAM Policies — `bootstrap/iam/`

Policy JSON files defining the minimum permissions for the GitLab CI IAM user per stack group. Apply via AWS console or CLI before configuring the runner.

| File                  | Grants                                              |
|-----------------------|-----------------------------------------------------|
| `cluster-policy.json` | VPC, EC2, EKS, IAM (cluster + node roles), S3, DynamoDB |
| `addons-policy.json`  | EKS describe, IAM (IRSA), ELB, Route53, S3, DynamoDB    |
| `apps-policy.json`    | EKS describe, ACM, Route53, S3, DynamoDB            |

All policies use `<ACCOUNT_ID>` as a placeholder — replace with the real AWS account ID before attaching.

---

## State file location

```
bootstrap/terraform.tfstate   ← local, committed to git
```

This is the **only** stack with local state. All other stacks use the S3 bucket that bootstrap creates.

---

## Apply order

```
bootstrap → cluster → addons/lbc → addons/externaldns → apps
```

Destroy in reverse:
```
apps → addons/externaldns → addons/lbc → cluster → bootstrap
```

---

## Importing existing resources

If the S3 bucket and DynamoDB table already exist (created manually before this stack was written), import them:

```bash
terraform import aws_s3_bucket.tfstate kk-eks-lab-tfstate
terraform import aws_s3_bucket_versioning.tfstate kk-eks-lab-tfstate
terraform import aws_s3_bucket_server_side_encryption_configuration.tfstate kk-eks-lab-tfstate
terraform import aws_s3_bucket_public_access_block.tfstate kk-eks-lab-tfstate
terraform import aws_dynamodb_table.tfstate_lock kk-eks-lab-tfstate-lock
```

---

## Usage

```bash
cd cluster-eks-terraform/bootstrap

export AWS_PROFILE=steven-prod

terraform init
terraform plan
terraform apply -auto-approve
```

Or via Docker (no local Terraform required):

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" -w /workspace \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 init

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" -w /workspace \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 apply -auto-approve
```

> Use the `steven-prod` IAM key — CI keys don't have S3/DynamoDB create permissions until bootstrap has run.

---

## Gotchas

- **Do not add a remote backend to this stack.** It creates the bucket — it cannot use the bucket as its own backend. Local state is correct and intentional.
- **The local `terraform.tfstate` is committed to git** so the team can see what bootstrap created without needing AWS access.
- **Single DynamoDB table** shared across all stacks and environments — state isolation is achieved via the S3 key path, not separate tables.
