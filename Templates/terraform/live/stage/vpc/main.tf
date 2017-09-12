provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true
  tags {
    Name        = "${var.customer_prefix} ${var.environment} VPC"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name        = "${var.customer_prefix} ${var.environment} Internet Gateway"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "rtpublic" {
  vpc_id                = "${aws_vpc.vpc.id}"
  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = "${aws_internet_gateway.igw.id}"
  }
  tags {
        Name        = "${var.customer_prefix} ${var.environment} Public Route Table"
  }
}

resource "aws_route_table_association" "rt1public" {
  subnet_id          = "${aws_subnet.az1-subnet-public.id}"
  route_table_id  = "${aws_route_table.rtpublic.id}"
}

resource "aws_route_table_association" "rt2public" {
  subnet_id          = "${aws_subnet.az2-subnet-public.id}"
  route_table_id  = "${aws_route_table.rtpublic.id}"
}

/*
  AZ1 Public Subnet
*/
resource "aws_subnet" "az1-subnet-public" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.public_subnet_cidr_1}"
  availability_zone = "${var.avalability_zone_1}"

  tags {
    Name        = "${var.customer_prefix} ${var.environment} AZ1 Public Subnet 1"
    Environment = "${var.environment}"
  }
}

/*
  AZ1 Private Subnet
*/
resource "aws_subnet" "az1-subnet-private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_1}"
  availability_zone = "${var.avalability_zone_1}"

  tags {
    Name        = "${var.customer_prefix} ${var.environment} AZ1 Private Subnet 1"
    Environment = "${var.environment}"
  }
}


resource "aws_route_table" "rt1private" {
  vpc_id                = "${aws_vpc.vpc.id}"
  route {
    cidr_block            = "0.0.0.0/0"
    network_interface_id  = "${var.private_interface_id_a}"
  }
  tags {
        Name        = "${var.customer_prefix} ${var.environment} Route Table Private Subnet 1"
        Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id         = "${aws_subnet.az1-subnet-private.id}"
  route_table_id    = "${aws_route_table.rt1private.id}"

}


/*
  AZ2 Public Subnet
*/
resource "aws_subnet" "az2-subnet-public" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.public_subnet_cidr_2}"
  availability_zone = "${var.avalability_zone_2}"

  tags {
    Name        = "${var.customer_prefix} ${var.environment} AZ2 Public Subnet 2"
    Environment = "${var.environment}"
  }
}

/*
  AZ2 Private Subnet
*/
resource "aws_subnet" "az2-subnet-private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_2}"
  availability_zone = "${var.avalability_zone_2}"

  tags {
    Name        = "${var.customer_prefix} ${var.environment} AZ2 Private Subnet 2"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "rt2private" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  route {
    cidr_block              = "0.0.0.0/0"
    network_interface_id    = "${var.private_interface_id_b}"
  }
  tags {
        Name        = "${var.customer_prefix} ${var.environment} Route Table Private Subnet 2"
        Environment = "${var.environment}"
  }
}


resource "aws_route_table_association" "rt2" {
  subnet_id         = "${aws_subnet.az2-subnet-private.id}"
  route_table_id    = "${aws_route_table.rt2private.id}"
}
