variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "team" {
  description = "Team prefix used for resource naming"
  type        = string
  default     = "kk"
}

variable "cluster_state_key" {
  description = "S3 key for the cluster Terraform state. Injected by CI per environment."
  type        = string
  default     = "cluster/terraform.tfstate"
}

variable "environment" {
  description = "Environment name used for resource naming"
  type        = string
  default     = "dev"
}
