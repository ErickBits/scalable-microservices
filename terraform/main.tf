terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # Guarda el estado de Terraform en S3 para trabajo en equipo
  # Descomenta y configura cuando vayas a usar esto en AWS real:
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "scalable-microservices/terraform.tfstate"
  #   region = var.aws_region
  # }
}

provider "aws" {
  region = var.aws_region
}
