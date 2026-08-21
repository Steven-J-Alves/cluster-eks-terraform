module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.cluster_version

  cluster_service_ipv4_cidr            = var.cluster_service_ipv4_cidr
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets

  eks_oidc_root_ca_thumbprint = var.eks_oidc_root_ca_thumbprint

  node_group_instance_types = var.node_group_instance_types
  node_group_desired_size   = var.node_group_desired_size
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_disk_size      = var.node_group_disk_size
  node_group_key_name       = var.instance_keypair

  tags = local.common_tags
}
