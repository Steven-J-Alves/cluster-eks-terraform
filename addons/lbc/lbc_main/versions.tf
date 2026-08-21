terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
  # key is injected at init via -backend-config="key=<env>/lbc/terraform.tfstate"
  backend "s3" {
    bucket         = "kk-eks-lab-tfstate"
    region         = "us-east-1"
    dynamodb_table = "kk-eks-lab-tfstate-lock"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "steven-prod"
}

provider "http" {}
