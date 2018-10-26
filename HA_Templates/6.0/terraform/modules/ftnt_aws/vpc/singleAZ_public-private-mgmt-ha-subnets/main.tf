resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.tag_name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.tag_name_prefix}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.public_subnet_cidr}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "${var.tag_name_prefix}-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.private_subnet_cidr}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "${var.tag_name_prefix}-private-subnet"
  }
}

resource "aws_subnet" "hasync_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.hasync_subnet_cidr}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "${var.tag_name_prefix}-hasync-subnet"
  }
}

resource "aws_subnet" "hamgmt_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.hamgmt_subnet_cidr}"
  availability_zone = "${var.availability_zone}"
  tags {
    Name = "${var.tag_name_prefix}-hamgmt-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags {
    Name = "${var.tag_name_prefix}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.tag_name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "public_rt_association1" {
  subnet_id = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "public_rt_association2" {
  subnet_id = "${aws_subnet.hamgmt_subnet.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "private_rt_association1" {
  subnet_id = "${aws_subnet.private_subnet.id}"
  route_table_id = "${aws_route_table.private_rt.id}"
}