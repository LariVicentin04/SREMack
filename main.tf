provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gateway"
  }
}

# Route Table and Association
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

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
    Name = "web-sg"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "SREMack_api" {
  name        = "SREMack-api"
  description = "SREMack API Gateway"
  endpoint_configuration {
    types = ["EDGE"]
  }
  tags = {
    Name = "SREMack-api"
  }
}

# Lambda Function Role
resource "aws_iam_role" "lambda_role" {
  name = "SREMack_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "SREMack_lambda" {
  function_name = "SREMack_lambda"
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  role          = aws_iam_role.lambda_role.arn

  filename         = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.SREMack.name
    }
  }

  tags = {
    Name = "SREMack_lambda"
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "SREMack" {
  name         = "SREMack_table"
  billing_mode = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key      = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

  tags = {
    Name = "SREMack_table"
  }
}

# RDS Instance
resource "aws_db_instance" "SREMack" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "SREMackdb"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  skip_final_snapshot  = true
  tags = {
    Name = "SREMack-rds"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "SREMack" {
  name = "SREMack_cluster"
  tags = {
    Name = "SREMack_cluster"
  }
}

resource "aws_ecs_task_definition" "SREMack_task" {
  family                   = "SREMack_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "SREMack_container"
      image     = "nginx"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  tags = {
    Name = "SREMack_task"
  }
}

resource "aws_ecs_service" "SREMack_service" {
  name            = "SREMack_service"
  cluster         = aws_ecs_cluster.SREMack.id
  task_definition = aws_ecs_task_definition.SREMack_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = {
    Name = "SREMack_service"
  }
}

# ALB
resource "aws_lb" "SREMack_lb" {
  name               = "SREMack_lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet.id]

  tags = {
    Name = "SREMack_lb"
  }
}

resource "aws_lb_target_group" "SREMack_tg" {
  name     = "SREMack_tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "SREMack_tg"
  }
}

resource "aws_lb_listener" "SREMack_listener" {
  load_balancer_arn = aws_lb.SREMack_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.SREMack_tg.arn
  }

  tags = {
    Name = "SREMack_listener"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "SREMack" {
  bucket = "SREMack_bucket"
  acl    = "private"

  tags = {
    Name = "SREMack_bucket"
  }
}
