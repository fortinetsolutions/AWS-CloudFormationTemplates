provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "fgcp-ha" {
  source = "modules/ftnt_aws/fgt/2instances_fgcp_ha_pair_byol"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"

  availability_zone = "${var.availability_zone}"
  vpc_id = "${var.vpc_id}"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet_id = "${var.public_subnet_id}"
  private_subnet_id = "${var.private_subnet_id}"
  hasync_subnet_id = "${var.hasync_subnet_id}"
  hamgmt_subnet_id = "${var.hamgmt_subnet_id}"
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

  fgt1_byol_license = "${var.fgt1_byol_license}"
  fgt1_eni0_ip1_cidr = "${var.fgt1_eni0_ip1_cidr}"
  fgt1_eni0_ip2_cidr = "${var.fgt1_eni0_ip2_cidr}"
  fgt1_eni1_ip1_cidr = "${var.fgt1_eni1_ip1_cidr}"
  fgt1_eni1_ip2_cidr = "${var.fgt1_eni1_ip2_cidr}"
  fgt1_eni2_ip1_cidr = "${var.fgt1_eni2_ip1_cidr}"
  fgt1_eni3_ip1_cidr = "${var.fgt1_eni3_ip1_cidr}"

  fgt2_byol_license = "${var.fgt2_byol_license}"
  fgt2_eni0_ip1_cidr = "${var.fgt2_eni0_ip1_cidr}"
  fgt2_eni1_ip1_cidr = "${var.fgt2_eni1_ip1_cidr}"
  fgt2_eni2_ip1_cidr = "${var.fgt2_eni2_ip1_cidr}"
  fgt2_eni3_ip1_cidr = "${var.fgt2_eni3_ip1_cidr}"
}