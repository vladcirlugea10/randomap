terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# This is the placeholder for each person's unique name.
# We will provide a value for it when we run `terraform apply`.
variable "student_identifier" {
  type        = string
  description = "A unique name for each student (e.g., 'nicu', 'tarabostes', 'mercedes', 'treiberi')."
}

provider "aws" {
  region = "us-east-1"
}

# This creates the "hat" (IAM Role) that App Runner can wear.
# It has a trust policy that says "Only the App Runner service can wear me".
resource "aws_iam_role" "app_runner_ecr_role" {
  name = "AppRunnerECRAccessRole-${var.student_identifier}"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

# This attaches the "keys" (permissions) to the hat.
# This specific AWS-managed policy gives all the permissions needed to pull from ECR.
resource "aws_iam_role_policy_attachment" "app_runner_ecr_policy_attachment" {
  role       = aws_iam_role.app_runner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# This resource creates a private container registry in AWS to store our Docker images.
# The name is made unique by adding the student_identifier.
resource "aws_ecr_repository" "app_repo" {
  name                 = "randomap-repo-${var.student_identifier}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# This resource creates the service that will run our container.
# It automatically handles networking, scaling, and security.
# Its name is also made unique by the student_identifier.
resource "aws_apprunner_service" "app_service" {
  service_name = "randomap-service-${var.student_identifier}"

  source_configuration {
    # ADD THIS BLOCK
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_ecr_role.arn
    }

    auto_deployments_enabled = true
    image_repository {
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "5000"
      }
    }
  }

  instance_configuration {
    cpu    = "256"
    memory = "512"
  }
}

# This tells Terraform to print out the final URL after everything is built.
output "app_url" {
  description = "The public URL of the App Runner service."
  value       = "https://${aws_apprunner_service.app_service.service_url}"
}