resource "aws_vpc" "webapp_vpc" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "webapp_subnet_1" {
  vpc_id            = aws_vpc.webapp_vpc.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "webapp_subnet_2" {
  vpc_id            = aws_vpc.webapp_vpc.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = "us-east-1b"
}