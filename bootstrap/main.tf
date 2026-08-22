# Bootstrap stack — apply this stack once before running any other stack.
# Uses local state stored in bootstrap/terraform.tfstate.
# This stack creates the S3 bucket and DynamoDB lock table that all other
# stacks (cluster / addons / apps) depend on for their S3 backend.

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # intentionally local — this stack creates the S3 bucket used by all other stacks
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# S3 bucket for Terraform remote state
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "tfstate" {
  bucket = var.bucket_name

  tags = {
    Project   = "kk-eks-lab"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# DynamoDB lock table — shared across all stacks
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "kk-eks-lab"
    ManagedBy = "terraform-bootstrap"
  }
}
