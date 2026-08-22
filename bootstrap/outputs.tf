output "tfstate_bucket_name" {
  description = "S3 bucket name used as remote backend by all stacks"
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table_name" {
  description = "DynamoDB lock table name shared by all stacks"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "state_key_cluster_prod" {
  description = "State key for cluster stack — prod"
  value       = "prod/cluster/terraform.tfstate"
}

output "state_key_cluster_staging" {
  description = "State key for cluster stack — staging"
  value       = "staging/cluster/terraform.tfstate"
}
