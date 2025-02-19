resource "aws_lb" "webapp_alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webapp_sg.id]
  subnets           = [aws_subnet.webapp_subnet_1.id, aws_subnet.webapp_subnet_2.id]
}

resource "aws_lb_target_group" "static_tg" {
  name     = "static-tg-${random_string.suffix.result}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp_vpc.id
}

resource "aws_lb_target_group" "api_tg" {
  name     = "api-tg-${random_string.suffix.result}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp_vpc.id
}

resource "aws_secretsmanager_secret" "trust_store" {
  name_prefix = "ec2-trust-store-"
}

resource "aws_s3_bucket" "trust_store_bucket" {
  bucket_prefix = "ec2-trust-store-"
}

resource "aws_iam_role" "lambda_exec" {
  name_prefix = "lambda_exec_role-"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
