# ================================================================================================================== #
# Cloudflare ACM 証書和 DNS 驗證
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
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type       # 會係 "CNAME"
      value  = dvo.resource_record_value      # 例如 xxx.acm-validations.aws.
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
  certificate_arn         = aws_acm_certificate.web_cert.arn
  validation_record_fqdns = [for record in cloudflare_dns_record.acm_validation :
    "${record.name}"
  ]
  depends_on = [cloudflare_dns_record.acm_validation]
}
# 不用在record.name後加這段, 會出error, stackoverflow好多人中招
# .${data.cloudflare_zone.main.name}.



# ================================================================================================================== #

# https://developer.hashicorp.com/terraform/language/resources/terraform-data
resource "terraform_data" "wait_for_alb_hostname" {
  # 等待 ALB 的 hostname 可用
  input = kubernetes_ingress_v1.flask_app_ingress.status[0].load_balancer[0].ingress[0].hostname
}


resource "cloudflare_record" "app_cname_to_alb" {
  zone_id = var.cloudflare_zone_id
  name    = var.app_domain_name # 你希望用哪個域名訪問 (例如 "www" 或 "@" 代表裸域名)
  value   = kubernetes_ingress_v1.flask_app_ingress.status[0].load_balancer[0].ingress[0].hostname
  type    = "CNAME"
  ttl     = 300 # DNS 記錄的 TTL (生存時間)，單位為秒，例如 5 分鐘
  proxied = true # 是否透過 Cloudflare 的 CDN/WAF 代理流量 (橙色雲朵)
                  # 建議設為 true 以利用 Cloudflare 的優勢，但在調試時可能設為 false

  depends_on = [terraform_data.wait_for_alb_hostname]
}

