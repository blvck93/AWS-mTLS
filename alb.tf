resource "aws_lb" "webapp_alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webapp_sg.id]
  subnets           = [aws_subnet.webapp_subnet_1.id, aws_subnet.webapp_subnet_2.id]
}


# Fetch the existing ACM certificate
data "aws_acm_certificate" "existing_cert" {
  domain   = "blvck.ovh"
  statuses = ["ISSUED"]  # Ensure it only fetches a valid issued certificate
}

# Use the existing certificate ARN for validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = data.aws_acm_certificate.existing_cert.arn
}


resource "random_string" "suffix" {
  length  = 10
  special = false
  upper   = false
}


resource "aws_lb_target_group" "api_tg" {
  name        = "api-tg-${random_string.suffix.result}"
  port        = 443
  protocol    = "HTTPS"
  target_type = "lambda"
  vpc_id      = aws_vpc.webapp_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    timeout             = 5
    path                = "/health"  # This path should be implemented in Lambda
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "mtls-lambda" {
  target_group_arn = aws_lb_target_group.api_tg.arn 
  target_id = aws_lambda_function.mtls_lambda.arn
}

resource "aws_lb_listener" "https_api" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.existing_cert.arn


  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn 
  }

  mutual_authentication {
    mode            = "verify"
    trust_store_arn = aws_lb_trust_store.alb_trust_store.arn
  }
}

resource "aws_lb_listener_rule" "forward_client_cert" {
  listener_arn = aws_lb_listener.https_api.arn
  priority     = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }

  condition {
    http_header {
      http_header_name = "x-amzn-tls-tls-client-cert-thumbprint"
      values           = [".*"]  # Match any certificate thumbprint
    }
  }
}