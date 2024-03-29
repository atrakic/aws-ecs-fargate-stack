data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Workspace = terraform.workspace
    Author    = data.aws_caller_identity.current.id
  }
}

module "db" {
  source    = "./modules/dynamodb"
  hash_key  = "artist"
  range_key = "title"
  configuration = {
    name = var.name
    attribute = [
      {
        name = "artist"
        type = "S"
      },
      {
        name = "title"
        type = "S"
      }
    ]

    global_secondary_indexes = [
      {
        name            = "TitleIndex"
        hash_key        = "artist"
        range_key       = "title"
        projection_type = "INCLUDE"
      }
    ]
  }
  tags = local.tags
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=26c38a66f12e7c6c93b6a2ba127ad68981a48671" # commit hash of version 5.0.0
  name   = var.name

  cidr                 = local.cidr
  azs                  = local.azs
  public_subnets       = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k)]
  private_subnets      = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k + 10)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags                 = local.tags
}
