module "vpc" {
  source = "../../../modules/vpc"

  name         = local.eks_cluster_name
  cidr         = var.vpc_cidr_block
  cluster_name = local.eks_cluster_name

  public_subnets   = var.vpc_public_subnets
  private_subnets  = var.vpc_private_subnets
  database_subnets = var.vpc_database_subnets

  create_database_subnet_group       = var.vpc_create_database_subnet_group
  create_database_subnet_route_table = var.vpc_create_database_subnet_route_table

  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway

  tags = local.common_tags
}
