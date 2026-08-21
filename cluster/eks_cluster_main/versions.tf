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
  backend "s3" {
    bucket         = "kk-eks-lab-tfstate"
    key            = "cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kk-eks-lab-tfstate-lock"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "steven-prod"
}
