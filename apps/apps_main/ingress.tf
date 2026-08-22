resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress-eks-lab"
    annotations = {
      "alb.ingress.kubernetes.io/load-balancer-name"             = local.lb_name
      "alb.ingress.kubernetes.io/scheme"                         = "internet-facing"
      "alb.ingress.kubernetes.io/healthcheck-protocol"           = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port"               = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds"   = 15
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"    = 5
      "alb.ingress.kubernetes.io/success-codes"                  = 200
      "alb.ingress.kubernetes.io/healthy-threshold-count"        = 2
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"      = 2
      "alb.ingress.kubernetes.io/listen-ports"                   = jsonencode([{ "HTTPS" = 443 }, { "HTTP" = 80 }])
      "alb.ingress.kubernetes.io/certificate-arn"                = aws_acm_certificate_validation.cert.certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect"                   = 443
      "external-dns.alpha.kubernetes.io/hostname"                = var.app_hostname
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    default_backend {
      service {
        name = kubernetes_service_v1.app_np[var.default_backend_app].metadata[0].name
        port { number = 80 }
      }
    }

    rule {
      http {
        dynamic "path" {
          for_each = local.routed_apps
          content {
            path      = path.value.ingress_path
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.app_np[path.key].metadata[0].name
                port { number = 80 }
              }
            }
          }
        }
      }
    }
  }
}
