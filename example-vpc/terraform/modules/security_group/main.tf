provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

resource "aws_security_group" "sg" {
  name = "${var.customer_prefix}-${var.environment}-${var.name}"
  description = "Allow required ports to the ec2 instance"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port   = "${var.ingress_from_port}"
    to_port     = "${var.ingress_to_port}"
    protocol    = "${var.ingress_protocol}"
    cidr_blocks = [ "${var.ingress_cidr_for_access}"]
  }
  egress {
    from_port   = "${var.egress_from_port}"
    to_port     = "${var.egress_to_port}"
    protocol    = "${var.egress_protocol}"
    cidr_blocks = [ "${var.ingress_cidr_for_access}"]
  }
  tags {
	Name = "${var.customer_prefix}-${var.environment}-SG"
    Environment = "${var.environment}"
  }
}
