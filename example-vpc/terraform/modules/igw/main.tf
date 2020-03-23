
provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
  tags = {
    Name        = "${var.customer_prefix}-${var.environment}-igw"
    Environment = var.environment
  }
}
