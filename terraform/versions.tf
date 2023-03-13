terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.58"
    }

    template = {
      source  = "hashicorp/template"
      version = ">= 2.2"
    }
  }
}
