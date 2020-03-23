provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_route_table" "gateway_route_table" {
  count                 = var.gateway_route
  vpc_id                = var.vpc_id
  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = var.igw_id
  }
  tags = {
        Name        = "${var.customer_prefix}-${var.environment}-${var.route_description}"
        Environment = var.environment
  }
}

resource "aws_route_table_association" "rt1aigw" {
  count              = var.gateway_route
  subnet_id          = var.subnet_id
  route_table_id     = aws_route_table.gateway_route_table[count.index].id
}

resource "aws_route_table" "eni_route_table" {
  count                 = var.eni_route
  vpc_id                = var.vpc_id
  route {
    cidr_block            = "0.0.0.0/0"
    network_interface_id  = var.eni_id
  }
  tags = {
        Name        = "${var.customer_prefix}-${var.environment}-${var.route_description}"
        Environment = var.environment
  }
}

resource "aws_route_table_association" "rt1aeni" {
  count              = var.eni_route
  subnet_id          = var.subnet_id
  route_table_id     = aws_route_table.eni_route_table[count.index].id
}
