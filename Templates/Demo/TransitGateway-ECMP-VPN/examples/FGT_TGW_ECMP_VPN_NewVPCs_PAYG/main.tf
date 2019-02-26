provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "transit-gw" {
  source = "modules/ftnt_aws/vpc/tgw"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  tag_name_prefix = "${var.tag_name_prefix}"
}

module "security-vpc" {
  source = "modules/ftnt_aws/vpc/vpc-security-tgw"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  
  availability_zone1 = "${var.availability_zone1}"
  availability_zone2 = "${var.availability_zone2}"
  vpc_cidr = "${var.security_vpc_cidr}"
  public_subnet_cidr1 = "${var.security_vpc_public_subnet_cidr1}"
  public_subnet_cidr2 = "${var.security_vpc_public_subnet_cidr2}"
  tag_name_prefix = "${var.tag_name_prefix}"
  tag_name_unique = "security"
}

module "spoke-vpc1" {
  source = "modules/ftnt_aws/vpc/vpc-spoke-tgw"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  
  availability_zone1 = "${var.availability_zone1}"
  availability_zone2 = "${var.availability_zone2}"
  vpc_cidr = "${var.spoke_vpc1_cidr}"
  private_subnet_cidr1 = "${var.spoke_vpc1_private_subnet_cidr1}"
  private_subnet_cidr2 = "${var.spoke_vpc1_private_subnet_cidr2}"
  transit_gateway_id = "${module.transit-gw.tgw_id}"
  transit_gateway_private_route_table = "${module.transit-gw.tgw_private_route_table_id}"  
  tag_name_prefix = "${var.tag_name_prefix}"
  tag_name_unique = "spoke1"
}

module "spoke-vpc2" {
  source = "modules/ftnt_aws/vpc/vpc-spoke-tgw"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  
  availability_zone1 = "${var.availability_zone1}"
  availability_zone2 = "${var.availability_zone2}"
  vpc_cidr = "${var.spoke_vpc2_cidr}"
  private_subnet_cidr1 = "${var.spoke_vpc2_private_subnet_cidr1}"
  private_subnet_cidr2 = "${var.spoke_vpc2_private_subnet_cidr2}"
  transit_gateway_id = "${module.transit-gw.tgw_id}"
  transit_gateway_private_route_table = "${module.transit-gw.tgw_private_route_table_id}"
  tag_name_prefix = "${var.tag_name_prefix}"
  tag_name_unique = "spoke2"
}

module "elb" {
  source = "modules/ftnt_aws/vpc/elb"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  
  public_elb_type = "${var.public_elb_type}"
  vpc_id = "${module.security-vpc.vpc_id}"
  public_subnet1_id = "${module.security-vpc.public_subnet1_id}"
  public_subnet2_id = "${module.security-vpc.public_subnet2_id}"
  fgt1_id = "${module.fgt1.fgt_id}"
  fgt2_id = "${module.fgt2.fgt_id}"
  tag_name_prefix = "${var.tag_name_prefix}"
  tag_name_unique = "public-${var.public_elb_type}"
}

module "fgt1" {
  source = "modules/ftnt_aws/fgt/1instance_tgw_vpn_payg"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"

  availability_zone = "${var.availability_zone1}"
  vpc_id = "${module.security-vpc.vpc_id}"
  vpc_cidr = "${var.security_vpc_cidr}"
  public_subnet_id = "${module.security-vpc.public_subnet1_id}"
  transit_gateway_id = "${module.transit-gw.tgw_id}"

  ami = "${var.license_type == "byol" ? lookup(var.fgt-byol-amis, var.region) : lookup(var.fgt-ond-amis, var.region)}"
  keypair = "${var.keypair}"  
  cidr_for_access = "${var.cidr_for_access}"
  instance_type = "${var.instance_type}"
  license_type = "${var.license_type}"
  bgp_asn = "${var.fgt_bgp_asn}"
  loopback_ip = "${var.fgt1_loopback_ip}"
  tag_name_prefix = "${var.tag_name_prefix}"
  tag_name_unique = "1"
}

module "fgt2" {
  source = "modules/ftnt_aws/fgt/1instance_tgw_vpn_payg"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"

  availability_zone = "${var.availability_zone2}"
  vpc_id = "${module.security-vpc.vpc_id}"
  vpc_cidr = "${var.security_vpc_cidr}"
  public_subnet_id = "${module.security-vpc.public_subnet2_id}"
  transit_gateway_id = "${module.transit-gw.tgw_id}"

  ami = "${var.license_type == "byol" ? lookup(var.fgt-byol-amis, var.region) : lookup(var.fgt-ond-amis, var.region)}"
  keypair = "${var.keypair}"  
  cidr_for_access = "${var.cidr_for_access}"
  instance_type = "${var.instance_type}"
  license_type = "${var.license_type}"
  bgp_asn = "${var.fgt_bgp_asn}"
  loopback_ip = "${var.fgt2_loopback_ip}"
  tag_name_prefix = "${var.tag_name_prefix}"
  tag_name_unique = "2"
}