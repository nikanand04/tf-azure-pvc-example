terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.3"
    }
  }
}

variable "pvc" {
}

variable "volume_name" {
  default = "my-volume"
}

# resource "kubernetes_namespace" "my_app" {
#   metadata {
#     name = "my-app"
#   }
# }

resource "kubernetes_deployment" "my_app_deployment" {
  metadata {
    name      = "my-app-deployment"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

      spec {

        container {
          image = "nginx:1.7.8"
          name  = "my-app"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/nginx_status"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

          volume_mount {
            mount_path = "/usr/share/my-app"
            name       = var.volume_name
          }
        }

        volume {
          name = var.volume_name
          persistent_volume_claim {
            claim_name = data.terraform_remote_state.pvc.outputs.kubernetes_pvc_name
          }
        }
      }
    }
  }
}

output "deployment_name" {
  value = kubernetes_deployment.my_app_deployment.metadata.0.name
}
