resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-vpc"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.private_subnet_cidr1}"
  availability_zone = "${var.availability_zone1}"
  tags {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-private-subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.private_subnet_cidr2}"
  availability_zone = "${var.availability_zone2}"
  tags {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-private-subnet2"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
	transit_gateway_id = "${var.transit_gateway_id}"
  }
  tags {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-private-rt"
  }
}

resource "aws_route_table_association" "private_rt_association1" {
  subnet_id = "${aws_subnet.private_subnet1.id}"
  route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_route_table_association" "private_rt_association2" {
  subnet_id = "${aws_subnet.private_subnet2.id}"
  route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  subnet_ids = ["${aws_subnet.private_subnet1.id}", "${aws_subnet.private_subnet2.id}"]
  transit_gateway_id = "${var.transit_gateway_id}"
  vpc_id = "${aws_vpc.vpc.id}"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = true
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_association" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id}"
  transit_gateway_route_table_id = "${var.transit_gateway_private_route_table}"
}