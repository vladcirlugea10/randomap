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
  region = "eu-central-1"
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
    # This magic line tells App Runner to automatically deploy when we push a new image.
    auto_deployments_enabled = true
    image_repository {
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }

  instance_configuration {
    port   = "5000"
  }
}

# This tells Terraform to print out the final URL after everything is built.
output "app_url" {
  description = "The public URL of the App Runner service."
  value       = "https://${aws_apprunner_service.app_service.service_url}"
}