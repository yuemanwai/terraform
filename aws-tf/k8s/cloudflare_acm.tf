# ================================================================================================================== #
# Cloudflare ACM certificate and DNS validation
# ================================================================================================================== #

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
resource "aws_acm_certificate" "web_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone
data "cloudflare_zone" "main" {
  zone_id = var.cloudflare_zone_id
}


# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record
resource "cloudflare_dns_record" "acm_validation" {
  for_each = {
    for dvo in tolist(aws_acm_certificate.web_cert.domain_validation_options) :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type  #  "CNAME"
      value = dvo.resource_record_value #  xxx.acm-validations.aws.
    }
  }

  zone_id = data.cloudflare_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.value
  ttl     = 300
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
resource "aws_acm_certificate_validation" "web_cert_validation" {
  certificate_arn = aws_acm_certificate.web_cert.arn
  validation_record_fqdns = [for record in cloudflare_dns_record.acm_validation :
    "${record.name}"
  ]
  depends_on = [cloudflare_dns_record.acm_validation]
}
# Do not append .${data.cloudflare_zone.main.name}. after record.name, it will cause errors.
# Many people on StackOverflow have encountered this issue.



# ================================================================================================================== #

# https://developer.hashicorp.com/terraform/language/resources/terraform-data
resource "terraform_data" "wait_for_alb_hostname" {
  # Wait for ALB hostname to be available
  input = kubernetes_ingress_v1.flask_app_ingress.status.0.load_balancer.0.ingress.0.hostname
}


resource "cloudflare_dns_record" "app_cname_to_alb" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  content = kubernetes_ingress_v1.flask_app_ingress.status.0.load_balancer.0.ingress.0.hostname
  type    = "CNAME"
  ttl     = 1 # when proxied is true, 1 means "automatic TTL"
  # Enable Cloudflare proxy (orange cloud) to leverage CDN features.
  # Set to false during debugging if needed.
  proxied = true

  depends_on = [terraform_data.wait_for_alb_hostname]
}
