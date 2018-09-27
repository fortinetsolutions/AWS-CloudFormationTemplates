provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "vpc" {
  source = "modules/ftnt_aws/vpc/singleAZ_public-private-mgmt-ha-subnets"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  
  availability_zone = "${var.availability_zone}"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet_cidr = "${var.public_subnet_cidr}"
  private_subnet_cidr = "${var.private_subnet_cidr}"
  hasync_subnet_cidr = "${var.hasync_subnet_cidr}"
  hamgmt_subnet_cidr = "${var.hamgmt_subnet_cidr}"
  tag_name_prefix = "${var.tag_name_prefix}"
}

module "fgcp-ha" {
  source = "modules/ftnt_aws/fgt/2instances_fgcp_ha_pair_payg"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"

  availability_zone = "${var.availability_zone}"
  vpc_id = "${module.vpc.vpc_id}"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet_id = "${module.vpc.public_subnet_id}"
  private_subnet_id = "${module.vpc.private_subnet_id}"
  hasync_subnet_id = "${module.vpc.hasync_subnet_id}"
  hamgmt_subnet_id = "${module.vpc.hamgmt_subnet_id}"
  ami = "${var.license_type == "byol" ? lookup(var.fgt-byol-amis, var.region) : lookup(var.fgt-ond-amis, var.region)}"
  tag_name_prefix = "${var.tag_name_prefix}"
  instance_type = "${var.instance_type}"
  license_type = "${var.license_type}"
  keypair = "${var.keypair}"  
  cidr_for_access = "${var.cidr_for_access}"
  public_subnet_intrinsic_router_ip = "${var.public_subnet_intrinsic_router_ip}"
  public_subnet_intrinsic_dns_ip = "${var.public_subnet_intrinsic_dns_ip}"
  private_subnet_intrinsic_router_ip = "${var.private_subnet_intrinsic_router_ip}"
  hamgmt_subnet_intrinsic_router_ip = "${var.hamgmt_subnet_intrinsic_router_ip}"

  fgt1_eni0_ip1_cidr = "${var.fgt1_eni0_ip1_cidr}"
  fgt1_eni0_ip2_cidr = "${var.fgt1_eni0_ip2_cidr}"
  fgt1_eni1_ip1_cidr = "${var.fgt1_eni1_ip1_cidr}"
  fgt1_eni1_ip2_cidr = "${var.fgt1_eni1_ip2_cidr}"
  fgt1_eni2_ip1_cidr = "${var.fgt1_eni2_ip1_cidr}"
  fgt1_eni3_ip1_cidr = "${var.fgt1_eni3_ip1_cidr}"

  fgt2_eni0_ip1_cidr = "${var.fgt2_eni0_ip1_cidr}"
  fgt2_eni1_ip1_cidr = "${var.fgt2_eni1_ip1_cidr}"
  fgt2_eni2_ip1_cidr = "${var.fgt2_eni2_ip1_cidr}"
  fgt2_eni3_ip1_cidr = "${var.fgt2_eni3_ip1_cidr}"
}