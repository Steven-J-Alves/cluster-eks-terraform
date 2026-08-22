resource "kubernetes_deployment_v1" "app" {
  for_each = var.apps

  metadata {
    name   = "${each.key}-nginx-deployment"
    labels = { app = "${each.key}-nginx" }
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = { app = "${each.key}-nginx" }
    }

    template {
      metadata {
        labels = { app = "${each.key}-nginx" }
      }

      spec {
        container {
          name  = "${each.key}-nginx"
          image = each.value.image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}
