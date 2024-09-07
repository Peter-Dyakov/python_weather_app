# Flask Weather App - Production Setup

This repository contains a Flask web application that displays the current weather for a given city. The app is containerized with Docker, deployed using **Terraform** on AWS, and managed using **GitHub Actions** for CI/CD automation. **Skaffold** is included for local development and Kubernetes deployment.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Local Development with Skaffold](#local-development-with-skaffold)
- [AWS Deployment using Terraform](#aws-deployment-using-terraform)
- [CI/CD with GitHub Actions](#cicd-with-github-actions)


## Project Overview

- **Flask Web App**: Displays the current temperature for a city using a weather API.
- **Infrastructure**: Terraform provisions two EC2 instances, AWS load balancer, ECR and dynamodb table.
- **Deployment**: The Dockerized app is built, pushed to Amazon Elastic Container Registry (ECR), and deployed to EC2 via GitHub Actions.
- **Local Development**: Skaffold is used for fast iteration and Kubernetes management.

## Prerequisites

1. **AWS Account** with EC2, ECR, and IAM access.
2. **GitHub Account**.
3. **Terraform** installed: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
4. **Skaffold** installed for local development: [Install Skaffold](https://skaffold.dev/docs/install/).
5. **Docker** installed for containerization.
6. **kubectl** installed for Kubernetes management.

## Local Development with Skaffold

For local development, we’ll use **Skaffold** with Kubernetes (via Minikube).

### Step 1: Start Minikube

Make sure Minikube is running:

```bash
minikube start
```

Configure Minikube to use the local Docker environment:

```bash
eval $(minikube docker-env)
```

### Step 2: Run the Application Locally with Skaffold

1. Clone the repository:

   ```bash
   git clone https://github.com/Peter-Dyakov/python_weather_app.git
   cd flask-weather-app
   ```
2. Create a Secret for the Weather API Token

   ```bash
   kubectl create secret generic weather-api-token --from-literal=WEATHER_API_TOKEN=your_weather_api_token_here
   ```
3. Run the application locally using Skaffold

    ```bash
    skaffold dev
    ```
4. Access the application in your browser

    ```bash
    kubectl port-forward service/flask-weather-app-service 8080:80
    ```
    The app is availble on http://localhost:8080/ URL

## AWS Deployment using Terraform

### Step 1: Create s3 bucket to store statefulset file
   ```bash
   aws s3api create-bucket --bucket lytx-assignment-terraform-state-bucket --region us-east-1
   aws s3api put-bucket-versioning --bucket lytx-assignment-terraform-state-bucket --versioning-configuration Status=Enabled

   ```

### Step 2: Set Up AWS Infrastructure with Terraform

   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```
Once Terraform has successfully provisioned the resources, you can access the application via the load balancer's DNS. Terraform will output this value as elb_dns_name.
    ```bash
    http://<elb_dns_name>
    ```

### Step 3: Deploy Application to EC2 via GitHub Actions

The GitHub Actions workflow is configured to trigger when a **pull request** is opened or updated on the `main` branch. The workflow will automatically perform the following steps:

1. **Build and push the Docker image**: 
   - The Flask application is containerized and the Docker image is built.
   - The image is then pushed to Amazon Elastic Container Registry (ECR).

2. **Deploy to EC2 instances**: 
   - After the image is pushed to ECR, the latest Docker image is pulled on both EC2 instances.
   - The currently running Flask application is stopped and replaced with the new version.

To ensure the workflow functions properly, the following GitHub Secrets need to be configured:
- `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID.
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.
- `ECR_REPOSITORY_URI`: The URI of your ECR repository.
- `EC2_PUBLIC_IP_1`: The public IP address of the first EC2 instance.
- `EC2_PUBLIC_IP_2`: The public IP address of the second EC2 instance.
- `EC2_SSH_KEY`: The private SSH key used to SSH into your EC2 instances.
- `WEATHER_API_TOKEN`: The token from free weather API site

This workflow ensures that any pull request to the `main` branch undergoes a full deployment pipeline, ensuring the application is automatically updated across the EC2 instances when the pull request is merged.


> **Note:** For a more secure deployment, it is better to use self-hosted builders and set a VPN for the connection between builders and application EC2 instances. This way, application EC2 instances can be placed on a private network and are not available from outside.