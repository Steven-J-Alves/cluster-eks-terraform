locals {
  owners      = var.team
  environment = var.environment
  name        = "${var.team}-${var.environment}"
  common_tags = {
    owners      = local.owners
    environment = local.environment
  }
  eks_cluster_name = "${local.name}-eks"
}
