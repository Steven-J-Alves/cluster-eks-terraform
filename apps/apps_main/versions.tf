terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
  # key is injected at init via -backend-config="key=<env>/apps/terraform.tfstate"
  backend "s3" {
    bucket         = "kk-eks-lab-tfstate"
    region         = "us-east-1"
    dynamodb_table = "kk-eks-lab-tfstate-lock"
  }
}
