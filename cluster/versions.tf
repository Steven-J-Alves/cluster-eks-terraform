terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = ">= 4.65"
      version = ">= 5.31"
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