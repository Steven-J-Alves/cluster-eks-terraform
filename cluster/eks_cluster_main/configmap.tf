data "aws_caller_identity" "current" {}

locals {
  configmap_roles = [
    {
      rolearn  = module.eks.nodegroup_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
  ]
}

resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [module.eks]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.configmap_roles)
  }
}
