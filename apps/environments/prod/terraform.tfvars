aws_region          = "us-east-1"
team                = "kk"
environment         = "prod"
cluster_state_key   = "prod/cluster/terraform.tfstate"
domain_name         = "kriolu-kloud.cv"
app_hostname        = "eks-lab.kriolu-kloud.cv"
ingress_class       = "my-aws-ingress-class"
default_backend_app = "app3"

apps = {
  app1 = {
    image        = "example/app1:1.0.0"
    replicas     = 1
    healthcheck  = "/app1/index.html"
    ingress_path = "/app1"
  }
  app2 = {
    image        = "example/app2:1.0.0"
    replicas     = 1
    healthcheck  = "/app2/index.html"
    ingress_path = "/app2"
  }
  app3 = {
    image       = "example/app3:1.0.0"
    replicas    = 1
    healthcheck = "/index.html"
  }
}
