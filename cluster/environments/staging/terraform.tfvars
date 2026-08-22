aws_region  = "us-east-1"
environment = "staging"
team        = "kk"

# VPC
vpc_cidr_block                         = "10.1.0.0/16"
vpc_public_subnets                     = ["10.1.101.0/24", "10.1.102.0/24"]
vpc_private_subnets                    = ["10.1.1.0/24", "10.1.2.0/24"]
vpc_database_subnets                   = ["10.1.151.0/24", "10.1.152.0/24"]
vpc_create_database_subnet_group       = true
vpc_create_database_subnet_route_table = true
vpc_enable_nat_gateway                 = true
vpc_single_nat_gateway                 = true

# EKS
cluster_version                      = "1.34"
cluster_service_ipv4_cidr            = "172.20.0.0/16"
cluster_endpoint_private_access      = false
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# Node Group
node_group_instance_types = ["t3.medium"]
node_group_desired_size   = 1
node_group_min_size       = 1
node_group_max_size       = 2
node_group_disk_size      = 20

# Bastion
instance_type    = "t3.micro"
instance_keypair = "kk-eks-lab-key"

# ci-test: trigger staging pipeline
