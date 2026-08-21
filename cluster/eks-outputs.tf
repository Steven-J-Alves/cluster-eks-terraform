output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}

output "aws_iam_openid_connect_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "aws_iam_openid_connect_provider_extract_from_arn" {
  value = module.eks.oidc_provider
}

output "node_group_private_status" {
  value = module.eks.node_group_private_status
}

output "node_group_private_version" {
  value = module.eks.node_group_private_version
}
