variable "s3_bucket_name" {
  description = "The name of the S3 bucket for Terraform state storage"
  default     = "lytx-assignment-terraform-state-bucket"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

variable "alb_az" {
  description = "The name of Load Balancer availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "environment" {
  description = "The environment name (e.g., dev, prod) for tagging and bucket naming"
  default     = "dev"
}


variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances"
  default     = "ami-0182f373e66f89c85"  # Amazon Linux 2 AMI ID for us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the application"
  default     = "flask-app-repo"
}


