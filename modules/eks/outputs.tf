output "cluster_id" {
  value = aws_eks_cluster.this.id
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  value = aws_eks_cluster.this.version
}

output "cluster_iam_role_arn" {
  value = aws_iam_role.cluster.arn
}

output "nodegroup_iam_role_arn" {
  value = aws_iam_role.nodegroup.arn
}

output "cluster_oidc_issuer_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_primary_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider" {
  value = element(split("oidc-provider/", aws_iam_openid_connect_provider.this.arn), 1)
}

output "node_group_private_status" {
  value = aws_eks_node_group.private.status
}

output "node_group_private_version" {
  value = aws_eks_node_group.private.version
}
