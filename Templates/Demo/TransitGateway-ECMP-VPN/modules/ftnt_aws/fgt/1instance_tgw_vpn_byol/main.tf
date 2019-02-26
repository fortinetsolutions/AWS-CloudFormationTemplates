provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_security_group" "secgrp" {
  name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-secgrp"
  description = "secgrp"
  vpc_id = "${var.vpc_id}"
  ingress {
    description = "Allow remote access to FGT"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.cidr_for_access}"]
  }
  ingress {
    description = "Allow local VPC access to FGT"
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
    Name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-secgrp"
  }
}

resource "aws_network_interface" "eni0" {
  subnet_id = "${var.public_subnet_id}"
  security_groups = [ "${aws_security_group.secgrp.id}" ]
  source_dest_check = false
  tags {
    Name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-eni0"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  network_interface = "${aws_network_interface.eni0.id}"
  tags {
    Name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-eip"
  }
}

resource "aws_customer_gateway" "cgw" {
  bgp_asn =  "${var.bgp_asn}"
  ip_address = "${aws_eip.eip.public_ip}"
  type = "ipsec.1"
  tags {
	Name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-cgw"
  }
}

resource "aws_vpn_connection" "vpn" {
  customer_gateway_id = "${aws_customer_gateway.cgw.id}"
  transit_gateway_id = "${var.transit_gateway_id}"
  type = "ipsec.1"
  static_routes_only = false
  tags {
	Name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-vpn"
  }
}

resource "aws_cloudwatch_metric_alarm" "fgt_ec2autorecovery" {
  alarm_name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}-ec2autorecovery"
  namespace = "AWS/EC2"
  evaluation_periods = "3"
  period = "300"
  alarm_description = "This metric auto recovers EC2 instances"
  alarm_actions = ["arn:aws:automate:${var.region}:ec2:recover"]
  statistic = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold = "0.0"
  metric_name = "StatusCheckFailed_System"
  dimensions {
    InstanceId = "${aws_instance.fgt.id}"
  }
}

resource "aws_instance" "fgt" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.availability_zone}"
  key_name = "${var.keypair}"
  user_data = "${data.template_file.fgt_userdata.rendered}"
  network_interface {
    device_index = 0
    network_interface_id = "${aws_network_interface.eni0.id}"
  }
  tags {
	Name = "${var.tag_name_prefix}-fgt${var.tag_name_unique}"
  }
}

data "template_file" "fgt_userdata" {
  template = "${file("${path.module}/fgt-userdata.tpl")}"

  vars {
    fgt_byol_license = "${file("${path.root}/${var.fgt_byol_license}")}"
    fgt_id = "fgt-${var.tag_name_unique}"
    fgt_ip = "${element(aws_network_interface.eni0.private_ips, 0)}"
	fgt_lpb = "${var.loopback_ip}"
    fgt_bgp = "${var.bgp_asn}"
    t1_id = "${aws_vpn_connection.vpn.id}-0"
    t1_ip = "${aws_vpn_connection.vpn.tunnel1_address}"
    t1_lip = "${aws_vpn_connection.vpn.tunnel1_cgw_inside_address}"
    t1_rip = "${aws_vpn_connection.vpn.tunnel1_vgw_inside_address}"
    t1_psk = "${aws_vpn_connection.vpn.tunnel1_preshared_key}"
    t1_bgp = "${aws_vpn_connection.vpn.tunnel1_bgp_asn}"
    t2_id = "${aws_vpn_connection.vpn.id}-1"
    t2_ip = "${aws_vpn_connection.vpn.tunnel2_address}"
    t2_lip = "${aws_vpn_connection.vpn.tunnel2_cgw_inside_address}"
    t2_rip = "${aws_vpn_connection.vpn.tunnel2_vgw_inside_address}"
    t2_psk = "${aws_vpn_connection.vpn.tunnel2_preshared_key}"
    t2_bgp = "${aws_vpn_connection.vpn.tunnel2_bgp_asn}"
  }
}