module "irsa_lbc" {
  source = "../../../modules/irsa"

  name              = "${local.name}-lbc"
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn
  namespace         = "kube-system"
  service_account   = "aws-load-balancer-controller"
  policy_document   = data.http.lbc_iam_policy.response_body

  tags = local.common_tags
}

output "lbc_iam_role_arn" {
  value = module.irsa_lbc.iam_role_arn
}

output "lbc_iam_policy_arn" {
  value = module.irsa_lbc.iam_policy_arn
}
