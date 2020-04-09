
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}


data "aws_ami" "fortigate_byol" {
  most_recent = true

  filter {
    name                         = "name"
    values                       = ["${var.fortigate_ami_string}"]
  }

  filter {
    name                         = "virtualization-type"
    values                       = ["hvm"]
  }

  owners                         = ["679593333241"] # Canonical
}

resource aws_security_group "allow_private_subnets" {
  name = "allow_private_subnets"
  description = "Allow all traffic from Private Subnets"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.private_subnet_cidr1}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_private_subnets"
  }
}

resource aws_security_group "allow_public_subnets" {
  name = "allow_public_subnets"
  description = "Allow all traffic from public Subnets"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.public_subnet_cidr1}", "${var.cidr_for_access}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_public_subnets"
  }
}

module "vpc" {
  source = "./modules/vpc"

  access_key                 = "${var.access_key}"
  secret_key                 = "${var.secret_key}"
  aws_region                 = "${var.aws_region}"
  environment                = "${var.environment}"
  customer_prefix            = "${var.customer_prefix}"
  vpc_cidr                   = "${var.vpc_cidr}"

}

module "igw" {
  source = "./modules/igw"

  access_key                 = "${var.access_key}"
  secret_key                 = "${var.secret_key}"
  aws_region                 = "${var.aws_region}"
  environment                = "${var.environment}"
  customer_prefix            = "${var.customer_prefix}"
  vpc_id                     = "${module.vpc.vpc_id}"
}

module "public-subnet-1" {
  source = "./modules/subnet"

  access_key                 = "${var.access_key}"
  secret_key                 = "${var.secret_key}"
  aws_region                 = "${var.aws_region}"
  environment                = "${var.environment}"
  customer_prefix            = "${var.customer_prefix}"
  vpc_id                     = "${module.vpc.vpc_id}"
  availability_zone          = "${var.availability_zone_1}"
  subnet_cidr                = "${var.public_subnet_cidr1}"
  subnet_description         = "${var.public1_description}"
}

module "private-subnet-1" {
  source = "./modules/subnet"

  access_key                 = "${var.access_key}"
  secret_key                 = "${var.secret_key}"
  aws_region                 = "${var.aws_region}"
  environment                = "${var.environment}"
  customer_prefix            = "${var.customer_prefix}"
  vpc_id                     = "${module.vpc.vpc_id}"
  availability_zone          = "${var.availability_zone_1}"
  subnet_cidr                = "${var.private_subnet_cidr1}"
  subnet_description         = "${var.private1_description}"
}

module "fortigate" {
  source                      = "./modules/fortigate_byol"

  access_key                  = "${var.access_key}"
  secret_key                  = "${var.secret_key}"
  aws_region                  = "${var.aws_region}"
  availability_zone           = "${var.availability_zone_1}"
  customer_prefix             = "${var.customer_prefix}"
  environment                 = "${var.environment}"
  public_subnet_id            = "${module.public-subnet-1.id}"
  public_ip_address           = "${var.public1_ip_address}"
  private_subnet_id           = "${module.private-subnet-1.id}"
  private_ip_address          = "${var.private1_ip_address}"
  aws_fgtbyol_ami             = "${data.aws_ami.fortigate_byol.id}"
  keypair                     = "${var.keypair}"
  fgt_instance_type           = "${var.fortigate_instance_type}"
  fortigate_instance_name     = "${var.fortigate_instance_name}"
  enable_public_ips           = "${var.public_ip}"
  security_group_private_id   = "${aws_security_group.allow_private_subnets.id}"
  security_group_public_id    = "${aws_security_group.allow_public_subnets.id}"
  acl                         = "${var.acl}"
  fgt_byol_license            = "${var.fgt_byol_license}"
  fgt_password_parameter_name = "${var.fgt_password_parameter_name}"
}

module "public1_route_table" {
  source                     = "./modules/route_table"

  access_key                 = "${var.access_key}"
  secret_key                 = "${var.secret_key}"
  aws_region                 = "${var.aws_region}"
  customer_prefix            = "${var.customer_prefix}"
  environment                = "${var.environment}"
  vpc_id                     = "${module.vpc.vpc_id}"
  eni_route                  = 0
  gateway_route              = 1
  eni_id                     = "${module.fortigate.network_public_interface_id}"
  igw_id                     = "${module.igw.igw_id}"
  subnet_id                  = "${module.public-subnet-1.id}"
  route_description          = "Public 1 Route Table"
}

module "private1_route_table" {
  source                     = "./modules/route_table"
  access_key                 = "${var.access_key}"
  secret_key                 = "${var.secret_key}"
  aws_region                 = "${var.aws_region}"
  customer_prefix            = "${var.customer_prefix}"
  environment                = "${var.environment}"
  vpc_id                     = "${module.vpc.vpc_id}"
  eni_route                  = 1
  gateway_route              = 0
  eni_id                     = "${module.fortigate.network_private_interface_id}"
  igw_id                     = "${module.igw.igw_id}"
  subnet_id                  = "${module.private-subnet-1.id}"
  route_description          = "Private 1 Route Table"
}
