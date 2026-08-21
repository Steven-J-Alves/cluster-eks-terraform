module "irsa_externaldns" {
  source = "../../modules/irsa"

  name              = "${local.name}-externaldns"
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn
  namespace         = "default"
  service_account   = "external-dns"
  policy_document   = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Resource = ["*"]
      }
    ]
  })

  tags = local.common_tags
}

output "externaldns_iam_role_arn" {
  value = module.irsa_externaldns.iam_role_arn
}

output "externaldns_iam_policy_arn" {
  value = module.irsa_externaldns.iam_policy_arn
}
