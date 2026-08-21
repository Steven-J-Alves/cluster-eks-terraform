data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "kk-eks-lab-tfstate"
    key    = var.cluster_state_key
    region = var.aws_region
  }
}
