provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "lytx-assignment-terraform-state-bucket"
    key            = "terraform/state"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # This enables state locking
  }
}


# DynamoDB Table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformStateLocks"
    Environment = var.environment
  }
}


# VPC, Subnet, and Internet Gateway Configuration
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "lytx-assignment"
  }
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Specify an AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"  # Specify a different AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 2"
  }
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

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id  # Associate with the public subnet
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id  # Associate with the public subnet
  route_table_id = aws_route_table.public.id
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
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "ec2_instances" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]  # Use vpc_security_group_ids
  # Assign EC2 instances to different subnets based on their index
  subnet_id = element([aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id], count.index)

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


# VPC, Subnet, and Security Group definitions should already be created above

# Security group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id   # Ensure this is the correct VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Allow HTTP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]   # Allow all outgoing traffic
  }

  tags = {
    Name = "ALB-SG"
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "app_alb" {
  name               = "flask-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]   # Use the security group created above
  # Specify at least two subnets in different Availability Zones
  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

# ALB Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "flask-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id   # Ensure this is the correct VPC

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Register EC2 Instances to Target Group
resource "aws_lb_target_group_attachment" "app_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.ec2_instances[0].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.ec2_instances[1].id
  port             = 80
}
