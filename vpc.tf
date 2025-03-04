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

resource "aws_internet_gateway" "webapp_igw" {
  vpc_id = aws_vpc.webapp_vpc.id
}

resource "aws_route_table" "webapp_rt" {
  vpc_id = aws_vpc.webapp_vpc.id
}

resource "aws_route" "webapp_route" {
  route_table_id         = aws_route_table.webapp_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.webapp_igw.id
}

resource "aws_route_table_association" "public_subnet1_rt" {
 subnet_id      = aws_subnet.webapp_subnet_1.id
 route_table_id = aws_route_table.webapp_rt.id
}

resource "aws_route_table_association" "public_subnet2_rt" {
 subnet_id      = aws_subnet.webapp_subnet_2.id
 route_table_id = aws_route_table.webapp_rt.id
}