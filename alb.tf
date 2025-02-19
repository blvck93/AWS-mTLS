resource "aws_lb" "webapp_alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webapp_sg.id]
  subnets           = [aws_subnet.webapp_subnet_1.id, aws_subnet.webapp_subnet_2.id]
}

resource "aws_lb_target_group" "static_tg" {
  name     = "static-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp_vpc.id
}

resource "aws_lb_target_group" "api_tg" {
  name     = "api-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp_vpc.id
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}