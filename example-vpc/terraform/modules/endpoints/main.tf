provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

resource "aws_instance" "ec2" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.keypair}"
  subnet_id     = "${var.subnet_id}"
  tags {
	Name = "${var.customer_prefix}-${var.environment}-EC2-${var.instance_count}"
    Environment = "${var.environment}"
  }
  associate_public_ip_address = "${var.public_ip}"
  vpc_security_group_ids = ["${var.security_group}"]
}
