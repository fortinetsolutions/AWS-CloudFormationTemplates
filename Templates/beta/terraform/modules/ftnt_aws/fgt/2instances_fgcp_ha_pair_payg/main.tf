provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_iam_role" "iam-role" {
  name = "${var.tag_name_prefix}-iam-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "${var.tag_name_prefix}-iam-instance-profile"
  role = "${var.tag_name_prefix}-iam-role"
}

resource "aws_iam_role_policy" "iam-role-policy" {
  name = "${var.tag_name_prefix}-iam-role-policy"
  role = "${aws_iam_role.iam-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
		"ec2:Describe*",
		"ec2:AssociateAddress",
		"ec2:AssignPrivateIpAddresses",
		"ec2:UnassignPrivateIpAddresses",
		"ec2:ReplaceRoute",
		"s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_security_group" "secgrp" {
  name = "${var.tag_name_prefix}-secgrp"
  description = "secgrp"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.cidr_for_access}"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "${var.tag_name_prefix}-fgt-secgrp"
  }
}

resource "aws_network_interface" "fgt1_eni0" {
  subnet_id = "${var.public_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt1_eni0_ip1_cidr)}", 0)}", "${element("${split("/", var.fgt1_eni0_ip2_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt1-eni0"
  }
}

resource "aws_network_interface" "fgt1_eni1" {
  subnet_id = "${var.private_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt1_eni1_ip1_cidr)}", 0)}", "${element("${split("/", var.fgt1_eni1_ip2_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt1-eni1"
  }
}

resource "aws_network_interface" "fgt1_eni2" {
  subnet_id = "${var.hasync_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt1_eni2_ip1_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt1-eni2"
  }
}

resource "aws_network_interface" "fgt1_eni3" {
  subnet_id = "${var.hamgmt_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt1_eni3_ip1_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt1-eni3"
  }
}

resource "aws_eip" "fgt1_bootstrap_eip" {
  vpc = true
  network_interface = "${aws_network_interface.fgt1_eni0.id}"
  associate_with_private_ip = "${element("${split("/", var.fgt1_eni0_ip1_cidr)}", 0)}"
  tags {
    Name = "${var.tag_name_prefix}-fgt1-bootstrap-eip"
  }
}

resource "aws_eip" "fgt1_hamgmt_eip" {
  vpc = true
  network_interface = "${aws_network_interface.fgt1_eni3.id}"
  associate_with_private_ip = "${element("${split("/", var.fgt1_eni3_ip1_cidr)}", 0)}"
  tags {
    Name = "${var.tag_name_prefix}-fgt1-hamgmt-eip"
  }
}

resource "aws_eip" "cluster_eip" {
  vpc = true
  network_interface = "${aws_network_interface.fgt1_eni0.id}"
  associate_with_private_ip = "${element("${split("/", var.fgt1_eni0_ip2_cidr)}", 0)}"
  tags {
    Name = "${var.tag_name_prefix}-cluster-eip"
  }
}

resource "aws_instance" "fgt1" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.availability_zone}"
  key_name = "${var.keypair}"
  iam_instance_profile = "${aws_iam_instance_profile.iam_instance_profile.id}"
  user_data = "${data.template_file.fgt1_userdata.rendered}"
  network_interface {
    device_index = 0
    network_interface_id = "${aws_network_interface.fgt1_eni0.id}"
  }
  network_interface {
    device_index = 1
    network_interface_id = "${aws_network_interface.fgt1_eni1.id}"
  }
  network_interface {
    device_index = 2
    network_interface_id = "${aws_network_interface.fgt1_eni2.id}"
  }
  network_interface {
    device_index = 3
    network_interface_id = "${aws_network_interface.fgt1_eni3.id}"
  }
  tags {
	Name = "${var.tag_name_prefix}-fgt1"
  }
}

data "template_file" "fgt1_userdata" {
  template = "${file("${path.module}/fgt1-userdata.tpl")}"
  
  vars {
    fgt1_eni0_ip2_cidr = "${var.fgt1_eni0_ip2_cidr}"
    fgt1_eni1_ip2_cidr = "${var.fgt1_eni1_ip2_cidr}"
    fgt1_eni2_ip1_cidr = "${var.fgt1_eni2_ip1_cidr}"
    fgt1_eni3_ip1_cidr = "${var.fgt1_eni3_ip1_cidr}"
    public_subnet_intrinsic_router_ip = "${var.public_subnet_intrinsic_router_ip}"
    vpc_cidr = "${var.vpc_cidr}"
    private_subnet_intrinsic_router_ip = "${var.private_subnet_intrinsic_router_ip}"
    public_subnet_intrinsic_dns_ip = "${var.public_subnet_intrinsic_dns_ip}"
    hamgmt_subnet_intrinsic_router_ip = "${var.hamgmt_subnet_intrinsic_router_ip}"
    fgt2_eni2_ip1 = "${element("${split("/", var.fgt2_eni2_ip1_cidr)}", 0)}"
  }
}

resource "aws_network_interface" "fgt2_eni0" {
  subnet_id = "${var.public_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt2_eni0_ip1_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt2-eni0"
  }
}

resource "aws_network_interface" "fgt2_eni1" {
  subnet_id = "${var.private_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt2_eni1_ip1_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt2-eni1"
  }
}

resource "aws_network_interface" "fgt2_eni2" {
  subnet_id = "${var.hasync_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt2_eni2_ip1_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt2-eni2"
  }
}

resource "aws_network_interface" "fgt2_eni3" {
  subnet_id = "${var.hamgmt_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  private_ips = [ "${element("${split("/", var.fgt2_eni3_ip1_cidr)}", 0)}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt2-eni3"
  }
}

resource "aws_eip" "fgt2_bootstrap_eip" {
  vpc = true
  network_interface = "${aws_network_interface.fgt2_eni0.id}"
  associate_with_private_ip = "${element("${split("/", var.fgt2_eni0_ip1_cidr)}", 0)}"
  tags {
    Name = "${var.tag_name_prefix}-fgt2-bootstrap-eip"
  }
}

resource "aws_eip" "fgt2_hamgmt_eip" {
  vpc = true
  network_interface = "${aws_network_interface.fgt2_eni3.id}"
  associate_with_private_ip = "${element("${split("/", var.fgt2_eni3_ip1_cidr)}", 0)}"
  tags {
    Name = "${var.tag_name_prefix}-fgt2-hamgmt-eip"
  }
}

resource "aws_instance" "fgt2" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.availability_zone}"
  key_name = "${var.keypair}"
  iam_instance_profile = "${aws_iam_instance_profile.iam_instance_profile.id}"
  user_data = "${data.template_file.fgt2_userdata.rendered}"
  network_interface {
    device_index = 0
    network_interface_id = "${aws_network_interface.fgt2_eni0.id}"
  }
  network_interface {
    device_index = 1
    network_interface_id = "${aws_network_interface.fgt2_eni1.id}"
  }
  network_interface {
    device_index = 2
    network_interface_id = "${aws_network_interface.fgt2_eni2.id}"
  }
  network_interface {
    device_index = 3
    network_interface_id = "${aws_network_interface.fgt2_eni3.id}"
  }
  tags {
	Name = "${var.tag_name_prefix}-fgt2"
  }
}

data "template_file" "fgt2_userdata" {
  template = "${file("${path.module}/fgt2-userdata.tpl")}"
  
  vars {
    fgt2_eni0_ip1_cidr = "${var.fgt2_eni0_ip1_cidr}"
    fgt2_eni1_ip1_cidr = "${var.fgt2_eni1_ip1_cidr}"
    fgt2_eni2_ip1_cidr = "${var.fgt2_eni2_ip1_cidr}"
    fgt2_eni3_ip1_cidr = "${var.fgt2_eni3_ip1_cidr}"
    public_subnet_intrinsic_router_ip = "${var.public_subnet_intrinsic_router_ip}"
    vpc_cidr = "${var.vpc_cidr}"
    private_subnet_intrinsic_router_ip = "${var.private_subnet_intrinsic_router_ip}"
    public_subnet_intrinsic_dns_ip = "${var.public_subnet_intrinsic_dns_ip}"
    hamgmt_subnet_intrinsic_router_ip = "${var.hamgmt_subnet_intrinsic_router_ip}"
    fgt1_eni2_ip1 = "${element("${split("/", var.fgt1_eni2_ip1_cidr)}", 0)}"
  }
}