resource "aws_security_group" "webapp_sg" {
  vpc_id = aws_vpc.webapp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-security-group"
  vpc_id      = aws_vpc.webapp_vpc.id

  # Allow outbound to EC2
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allows Lambda to connect anywhere
  }
}

# Allow Lambda to access EC2
resource "aws_security_group_rule" "allow_lambda_to_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.webapp_sg.id  # EC2 security group
  source_security_group_id = aws_security_group.lambda_sg.id  # Lambda security group
}