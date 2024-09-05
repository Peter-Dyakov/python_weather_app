provider "aws" {
  region = var.aws_region
}

# VPC, Subnet, and Internet Gateway Configuration
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr_block
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id

  # Allow incoming HTTP traffic to ALB from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "ALB-SG"
  }
}

# Security Group for EC2 Instances
resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.vpc.id

  # Allow SSH from your IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP traffic only from the ALB security group
  ingress {
    from_port      = 80
    to_port        = 80
    protocol       = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

# Key Pair for SSH Access
resource "aws_key_pair" "deployer_key_pair" {
  key_name   = "deployer_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# EC2 Instances
resource "aws_instance" "ec2_instances" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer_key_pair.key_name
  security_groups = [aws_security_group.allow_ssh_http.name]
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "FlaskApp-${count.index}"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              EOF
}

# Load Balancer (ALB)
resource "aws_elb" "app_elb" {
  name               = "flask-app-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  security_groups    = [aws_security_group.alb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  instances = aws_instance.ec2_instances[*].id

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "FlaskAppELB"
  }
}

# ECR Repository for Docker Images
resource "aws_ecr_repository" "flask_app_repo" {
  name = var.ecr_repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "FlaskAppECR"
  }
}

# Outputs for ECR Repository and Load Balancer DNS
output "ecr_repository_url" {
  value = aws_ecr_repository.flask_app_repo.repository_url
}

output "elb_dns_name" {
  value = aws_elb.app_elb.dns_name
}

# Output Public IPs of EC2 Instances
output "ec2_instance_1_public_ip" {
  description = "The public IP address of the first EC2 instance"
  value       = aws_instance.ec2_instances[0].public_ip
}

output "ec2_instance_2_public_ip" {
  description = "The public IP address of the second EC2 instance"
  value       = aws_instance.ec2_instances[1].public_ip
}
