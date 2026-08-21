output "iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "iam_policy_arn" {
  value = aws_iam_policy.this.arn
}
