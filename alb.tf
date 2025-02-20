resource "aws_lb" "webapp_alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webapp_sg.id]
  subnets           = [aws_subnet.webapp_subnet_1.id, aws_subnet.webapp_subnet_2.id]
}


# Request and validate an SSL certificate from AWS Certificate Manager (ACM)
resource "aws_acm_certificate" "my_certificate" {
  domain_name       = "blvck.ovh"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.my_certificate.arn
}

# Associate the SSL certificate with the ALB listener
resource "aws_lb_listener_certificate" "my-certificate" {
  listener_arn = aws_lb_listener.https_web.arn
  certificate_arn = aws_acm_certificate.my_certificate.arn
}

resource "aws_lb_listener_certificate" "my-certificate2" {
  listener_arn = aws_lb_listener.https_api.arn
  certificate_arn = aws_acm_certificate.my_certificate.arn
}

resource "random_string" "suffix" {
  length  = 10
  special = false
  upper   = false
}

resource "aws_lb_target_group" "static_tg" {
  name     = "static-tg-${random_string.suffix.result}"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.webapp_vpc.id
}

resource "aws_lb_target_group" "api_tg" {
  name     = "api-tg-${random_string.suffix.result}"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.webapp_vpc.id
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.static_tg.arn
  target_id        = aws_instance.webapp_ec2.id
}

resource "aws_lb_listener" "https_web" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static_tg.arn
  }
}

resource "aws_lb_listener" "https_api" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"


  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn 
  }
}


resource "aws_lb_listener_rule" "api_mtls_rule" {
  listener_arn = aws_lb_listener.https_api.arn
  priority     = 100

  condition {
    http_header {
      http_header_name = "x-amzn-tls-client-cert"
      values           = ["*"] # This ensures a client certificate is present
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}