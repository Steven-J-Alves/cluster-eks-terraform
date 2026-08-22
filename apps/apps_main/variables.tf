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

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "dev"
}

variable "cluster_state_key" {
  description = "S3 key for the cluster Terraform state. Injected by CI per environment."
  type        = string
  default     = "cluster/terraform.tfstate"
}

variable "domain_name" {
  description = "Base domain for ACM wildcard cert and Route53 zone lookup"
  type        = string
  default     = "kriolu-kloud.cv"
}

variable "app_hostname" {
  description = "Public DNS hostname ExternalDNS will register for the ALB"
  type        = string
  default     = "eks-lab.kriolu-kloud.cv"
}

variable "ingress_class" {
  description = "IngressClass name created by the AWS Load Balancer Controller"
  type        = string
  default     = "my-aws-ingress-class"
}

variable "default_backend_app" {
  description = "Key from var.apps to use as the Ingress default backend (catches all unmatched paths)"
  type        = string
  default     = "app3"
}

variable "apps" {
  description = "Map of applications to deploy. ingress_path = null means default backend only."
  type = map(object({
    image        = string
    replicas     = optional(number, 1)
    healthcheck  = string
    ingress_path = optional(string)
  }))
  default = {
    app1 = {
      image        = "example/app1:1.0.0"
      healthcheck  = "/app1/index.html"
      ingress_path = "/app1"
    }
    app2 = {
      image        = "example/app2:1.0.0"
      healthcheck  = "/app2/index.html"
      ingress_path = "/app2"
    }
    app3 = {
      image       = "example/app3:1.0.0"
      healthcheck = "/index.html"
    }
  }
}
