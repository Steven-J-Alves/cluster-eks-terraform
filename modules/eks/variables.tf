variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "cluster_service_ipv4_cidr" {
  type    = string
  default = null
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = false
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_oidc_root_ca_thumbprint" {
  type    = string
  default = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}

variable "node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_group_desired_size" {
  type    = number
  default = 1
}

variable "node_group_min_size" {
  type    = number
  default = 1
}

variable "node_group_max_size" {
  type    = number
  default = 2
}

variable "node_group_disk_size" {
  type    = number
  default = 20
}

variable "node_group_key_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
