terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_network_interface" "ENI0" {
  subnet_id                   = "${var.public_subnet_id}"
  security_groups             = [ "${var.security_group_ids}" ]
  source_dest_check           = true

  tags {
    Name        = "${var.customer_prefix}-${var.aws_region}-${var.environment}-${var.worker_node_instance_name}ENI0 "
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "EIP" {
  count                 = "${var.enable_public_ips}"
  vpc                   = true
  network_interface     = "${aws_network_interface.ENI0.id}"

}
resource "aws_instance" "worker_node" {

  ami                         = "${var.aws_wn_amis}"
  instance_type               = "${var.worker_node_instance_type}"
  availability_zone           = "${var.availability_zone}"
  network_interface   = {
    network_interface_id  = "${aws_network_interface.ENI0.id}"
    device_index = 0
  }
  iam_instance_profile    = "${var.instance_profile}"
  key_name                = "${var.key_name}"
  tags {
    Name                  = "${var.customer_prefix}-${var.aws_region}-${var.environment}-${var.worker_node_instance_name}"
    Customer_Prefix       = "${var.customer_prefix}"
    Environment           = "${var.environment}"
    Region                = "${var.aws_region}"
  }
}

