data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../../../infrastructure/terraform.tfstate.d/${var.environment}/terraform.tfstate"
  }
}

locals {
  is_localstack = contains(["production", "staging"], var.environment) ? false : true
}

resource "null_resource" "docker_image_build" {
  triggers = {
    file_hashes = jsonencode({
      for fn in fileset("${path.module}/..", "*") :
      fn => filesha256("${path.module}/../${fn}")
    })
  }

  provisioner "local-exec" {
    command = "${path.module}/../../../.github/scripts/build.sh ${var.microservice_name} ${var.microservice_version} ${local.is_localstack}"
  }
}

data "local_file" "docker_image_sha" {
  filename = "${path.module}/../.dockerimage"
  depends_on = [
    null_resource.docker_image_build
  ]
}

locals {
  deployment_name = "${var.microservice_name}-${var.environment}"
  ingress_name    = "${var.microservice_name}-${var.environment}"
  service_name    = "${var.microservice_name}-${var.environment}"

  namespace_name = data.terraform_remote_state.infrastructure.outputs.namespace_name

  docker_image_name = "${var.microservice_name}:${data.local_file.docker_image_sha.content}"
}

resource "kubernetes_deployment_v1" "api" {
  metadata {
    name = local.deployment_name
    labels = {
      app = var.microservice_name
    }
    namespace = local.namespace_name
  }

  spec {
    replicas = var.microservice_replicas

    selector {
      match_labels = {
        app = var.microservice_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.microservice_name
        }
      }

      spec {
        container {
          image             = local.docker_image_name
          name              = var.microservice_name
          image_pull_policy = "Never"
          port {
            container_port = var.port
          }
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
              path   = "/health"
              port   = 8080
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path   = "/health"
              port   = 8080
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          security_context {
            read_only_root_filesystem = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "api" {
  metadata {
    name      = local.service_name
    namespace = local.namespace_name
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.api.metadata[0].labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = var.port
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "api" {
  metadata {
    name      = local.ingress_name
    namespace = local.namespace_name
  }

  spec {
    default_backend {
      service {
        name = local.service_name
        port {
          number = var.port
        }
      }
    }

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = local.service_name
              port {
                number = var.port
              }
            }
          }
        }
      }
    }

    ingress_class_name = "nginx"

    tls {
      secret_name = "tls-secret"
    }
  }
}
