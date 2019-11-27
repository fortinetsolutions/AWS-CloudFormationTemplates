
provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_vpc" "vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true
  tags {
    Name        = "${var.customer_prefix}-${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name        = "${var.customer_prefix}-${var.environment}-igw"
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
        Name        = "${var.customer_prefix}-${var.environment}-rtpublic"
        Environment = "${var.environment}"
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
  availability_zone = "${var.availability_zone1}"

  tags {
    Name        = "${var.customer_prefix}-${var.environment}-public-subnet1"
    Environment = "${var.environment}"
  }
}

/*
  AZ1 Private Subnet
*/
resource "aws_subnet" "az1-subnet-private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_1}"
  availability_zone = "${var.availability_zone1}"

  tags {
    Name        = "${var.customer_prefix}-${var.environment}-private-subnet1"
    Environment = "${var.environment}"
  }
}


resource "aws_route_table" "rt1private" {
  vpc_id                = "${aws_vpc.vpc.id}"
  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id  = "${aws_internet_gateway.igw.id}"
  }
  tags {
        Name        = "${var.customer_prefix}-${var.environment}-rtprivate1"
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
  availability_zone = "${var.availability_zone2}"

  tags {
    Name        = "${var.customer_prefix}-${var.environment}-public-subnet2"
    Environment = "${var.environment}"
  }
}

/*
  AZ2 Private Subnet
*/
resource "aws_subnet" "az2-subnet-private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_2}"
  availability_zone = "${var.availability_zone2}"

  tags {
    Name        = "${var.customer_prefix}-${var.environment}-private-subnet2"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "rt2private" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = "${aws_internet_gateway.igw.id}"
  }
  tags {
        Name        = "${var.customer_prefix}-${var.environment}-rtprivate2"
        Environment = "${var.environment}"
  }
}


resource "aws_route_table_association" "rt2" {
  subnet_id         = "${aws_subnet.az2-subnet-private.id}"
  route_table_id    = "${aws_route_table.rt2private.id}"
}
