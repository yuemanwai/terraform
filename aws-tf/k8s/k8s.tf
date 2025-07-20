
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.vpc.outputs.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.cluster.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# ================================================================================================================== #

resource "kubernetes_secret_v1" "demo-secret" {
  metadata {
    name = "my-secret"
  }

  data = {
    username = base64encode("demo-Username-Admin3456") # Replace with your actual username
    password = base64encode("demo-Pw-hfds78hafhU")     # Replace with your actual password
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "nginx" {
  depends_on = [kubernetes_secret_v1.demo-secret] # Ensure the secret is created before the deployment

  metadata {
    name = "my-app-example"
    labels = {
      App = "my-app"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "my-app"
      }
    }
    template {
      metadata {
        labels = {
          App = "my-app"
        }
      }
      spec {
        container {
          image = "yuemanwai/simple-website:latest" # nginx:1.7.8
          name  = "example"

          port {
            container_port = 80 # This should match the port exposed by the container
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

          env {
            name = "USERNAME" # Example environment variable
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.demo-secret.metadata[0].name # This should match the name of the secret created above
                key  = "username"                                      # Ensure this key exists in the secret
                # Note: `key` should match the keys defined in the `kubernetes_secret_v1` resource.
                # This will fetch the value of `username` from the secret and set it as an environment variable in the container.
              }
            }
          }

          env {
            name = "PASSWORD" # Another example environment variable
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.demo-secret.metadata[0].name
                key  = "password" # Ensure this key exists in the secret
                # Note: `key` should match the keys defined in the `kubernetes_secret_v1` resource.
                # This will fetch the value of `password` from the secret and set it as an environment variable in the container.
              }
            }
          }


        }
      }
    }
  }
}


resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-example"
    namespace = "default"

  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80 # This is the port on which the service will be exposed
      target_port = 80 # This should match the container port in the deployment
    }

    type = "LoadBalancer"
  }
}

