# output "lb_ip" {
#   value = kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname
# }

output "alb_dns_name" {
  description = "The DNS name of the ALB created by the Ingress."
  # 僅在 ingress 資源有 status.loadBalancer.ingress 字段時才輸出
  value       = try(kubernetes_ingress_v1.flask_app_ingress.status[0].load_balancer[0].ingress[0].hostname, "ALB DNS Name not available yet.")
}

output "flask_app_url" {
  description = "The primary URL for the Flask application (HTTPS)."
  value       = "https://${var.domain_name}"
}