provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_network_interface" "ENI0" {
  subnet_id                   = "${var.public1_subnet_id}"
  security_groups             = [ "${var.security_group_ids}" ]
  source_dest_check           = true

  tags {
    Name        = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}ENI0 "
    Environment = "${var.environment}"
  }
}

resource "aws_network_interface" "ENI1" {
  subnet_id                   = "${var.private1_subnet_id}"
  security_groups             = [ "${var.security_group_ids}" ]
  source_dest_check           = false

  tags {
    Name        = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}ENI1 "
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "EIP" {
  count                 = "${var.enable_public_ips}"
  vpc                   = true
  network_interface     = "${aws_network_interface.ENI0.id}"

}
resource "aws_instance" "fortigate" {

  ami                         = "${var.aws_fgtod_amis}"
  instance_type               = "${var.fgt_instance_type}"
  availability_zone           = "${var.availability_zone_1}"
  network_interface   = {
    network_interface_id = "${aws_network_interface.ENI0.id}"
    device_index = 0
  }
  network_interface {
    device_index = 1
    network_interface_id   = "${aws_network_interface.ENI1.id}"
  }
  tags {
    Name            = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}"
    Environment     = "${var.environment}"
    Fortinet-Role   = "${var.fortigate_instance_name}"
    Fortigate-State = "UnConfigured"
  }
}

