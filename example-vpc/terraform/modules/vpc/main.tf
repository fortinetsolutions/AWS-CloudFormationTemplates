
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "vpc" {
  cidr_block            = var.vpc_cidr
  enable_dns_hostnames  = true
  tags = {
    Name                = "${var.customer_prefix}-${var.environment}-vpc"
    Environment         = var.environment
  }
}
