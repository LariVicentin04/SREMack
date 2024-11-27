# terraform plan
resource "aws_vpc" "SREMack" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "SREMack-vpc"
  }
}

resource "aws_subnet" "SREpublic_subnet" {
  vpc_id            = aws_vpc.SREMack.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "SREpublic-subnet"
  }
}

resource "aws_subnet" "SREprivate_subnet" {
  vpc_id            = aws_vpc.SREMack.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "SREprivate-subnet"
  }
}

resource "aws_internet_gateway" "SREMack" {
  vpc_id = aws_vpc.SREMack.id
  tags = {
    Name = "SREMack-gateway"
  }
}

resource "aws_route_table" "SREMack_public" {
  vpc_id = aws_vpc.SREMack.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.SREMack.id
  }

  tags = {
    Name = "SREMack-public-route-table"
  }
}

resource "aws_route_table_association" "SREMack_public" {
  subnet_id      = aws_subnet.SREpublic_subnet.id
  route_table_id = aws_route_table.SREMack_public.id
}

resource "aws_security_group" "SREMack_web_sg" {
  name        = "SREMack-web-sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.SREMack.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SREMack-web-sg"
  }
}
