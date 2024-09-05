variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
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
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI ID for us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the application"
  default     = "flask-app-repo"
}
