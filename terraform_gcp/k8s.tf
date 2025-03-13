provider "kubernetes" {
  host                   = google_container_cluster.default.endpoint
  token                  = data.google_client_config.current.access_token
  client_certificate     = base64decode(google_container_cluster.default.master_auth[0].client_certificate)
  client_key             = base64decode(google_container_cluster.default.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "google_compute_address" "default" {
  name    = var.network_name
  region  = var.region
  project = var.project
}

resource "kubernetes_service" "simple-website" {
  metadata {
    namespace = kubernetes_namespace.staging.metadata[0].name
    name      = "simple-website"
  }

  spec {
    selector = {
      run = "simple-website"
    }

    session_affinity = "ClientIP"

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_replication_controller" "simple-website" {
  metadata {
    name      = "simple-website"
    namespace = kubernetes_namespace.staging.metadata[0].name
    labels = {
      run = "simple-website"
    }
  }

  spec {
    selector = {
      run = "simple-website"
    }

    template {
      metadata {
        labels = {
          run = "simple-website"
        }
      }

      spec {
        container {
          image = "yuemanwai/simple-website:latest"
          name  = "simple-website"

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
        }
      }
    }
  }
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}

output "endpoint" {
  value = google_container_cluster.default.endpoint
}