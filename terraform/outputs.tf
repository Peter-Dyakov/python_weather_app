# Outputs for ECR Repository and Load Balancer DNS
output "ecr_repository_url" {
  value = aws_ecr_repository.flask_app_repo.repository_url
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
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