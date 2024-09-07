resource "aws_iam_role" "ec2_instance_role" {
  name = "flask-app-instance-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }]
  })
}

resource "aws_iam_role_policy" "ecr_access_policy" {
  name   = "ecr-access-policy"
  role   = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "flask-app-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}
