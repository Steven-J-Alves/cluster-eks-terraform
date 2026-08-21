variable "name" {
  type        = string
  description = "Name for the IAM role and policy"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider"
}

variable "oidc_provider" {
  type        = string
  description = "OIDC provider URL extracted from ARN (without https://)"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the service account"
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account name"
}

variable "policy_document" {
  type        = string
  description = "JSON policy document to attach to the IAM role"
}

variable "tags" {
  type    = map(string)
  default = {}
}
