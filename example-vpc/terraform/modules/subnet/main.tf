
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone

  tags= {
    Name        = "${var.customer_prefix}-${var.environment}-${var.subnet_description}-subnet"
    Environment = var.environment
  }
}
