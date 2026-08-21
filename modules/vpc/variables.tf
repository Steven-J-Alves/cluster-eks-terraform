variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "database_subnets" {
  type    = list(string)
  default = []
}

variable "create_database_subnet_group" {
  type    = bool
  default = true
}

variable "create_database_subnet_route_table" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name used for subnet tagging"
}

variable "tags" {
  type    = map(string)
  default = {}
}
