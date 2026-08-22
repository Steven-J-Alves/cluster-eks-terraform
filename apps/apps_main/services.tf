resource "kubernetes_service_v1" "app_np" {
  for_each = var.apps

  metadata {
    name = "${each.key}-nginx-nodeport-service"
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = each.value.healthcheck
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.app[each.key].spec[0].selector[0].match_labels.app
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}
