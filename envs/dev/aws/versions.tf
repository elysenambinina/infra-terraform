terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket       = "tfstate-elyse-gitops"
    key          = "dev/aws/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = { Project = "gitops-eks", Environment = "dev", ManagedBy = "terraform" }
  }
}

variable "admin_ip" {
  description = "Adresse IP publique autorisée à joindre l'API Kubernetes (fichier admin.auto.tfvars)"
  type        = string
}

locals {
  name = "gitops-dev"
  azs  = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}
