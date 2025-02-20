resource "aws_route53_record" "web_alias" {
  zone_id = aws_route53_zone.blvck_ovh.zone_id
  name    = "web.blvck.ovh"
  type    = "A"

  alias {
    name                   = aws_lb.webapp_alb.dns_name
    zone_id                = aws_lb.webapp_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_alias" {
  zone_id = aws_route53_zone.blvck_ovh.zone_id
  name    = "api.blvck.ovh"
  type    = "A"

  alias {
    name                   = aws_lb.webapp_alb.dns_name
    zone_id                = aws_lb.webapp_alb.zone_id
    evaluate_target_health = true
  }
}
