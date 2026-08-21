terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = ">= 4.65"
      version = ">= 5.31"
     }
    helm = {
      source = "hashicorp/helm"
      #version = "2.5.1"
      #version = "~> 2.5"
      version = "~> 2.9"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      #version = "~> 2.11"
      version = ">= 2.20"
    }      
  }
  backend "s3" {
    bucket         = "kk-eks-lab-tfstate"
    key            = "externaldns/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kk-eks-lab-tfstate-lock"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "steven-prod"
}

