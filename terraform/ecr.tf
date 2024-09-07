resource "aws_ecr_repository" "flask_app_repo" {
  name = "flask-app-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "FlaskAppECR"
  }
}
