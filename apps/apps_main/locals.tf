locals {
  lb_name     = "${var.team}-${var.environment}-eks-lab"
  routed_apps = { for k, v in var.apps : k => v if v.ingress_path != null }
}
