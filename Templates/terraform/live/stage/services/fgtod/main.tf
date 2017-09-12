terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "fgt_a" {

  source = "../../../../modules/services/fortigate"

  aws_region		          = "${var.aws_region}"
  environment                 = "${var.environment}"
  customer_prefix             = "${var.customer_prefix}"
  aws_fgtod_amis              = "${lookup(var.fortigate-od-amis, var.aws_region)}"
  fgt_instance_type           = "${var.fgt_instance_type}"
  availability_zone           = "${var.availability_zone_1}"
  fortigate_instance_name     = "OnDemandA"
  public_subnet_id            = "${var.public1_subnet_id}"
  private_subnet_id           = "${var.private1_subnet_id}"
  enable_public_ips           = "${var.enable_public_ips}"
  security_group_ids          = "${var.security_group_ids}"
  api_termination_protection  = "${var.api_termination_protection}"
}

module "fgt_b" {

  source = "../../../../modules/services/fortigate"

  aws_region		          = "${var.aws_region}"
  environment                 = "${var.environment}"
  customer_prefix             = "${var.customer_prefix}"
  aws_fgtod_amis              = "${lookup(var.fortigate-od-amis, var.aws_region)}"
  fgt_instance_type           = "${var.fgt_instance_type}"
  availability_zone           = "${var.availability_zone_2}"
  fortigate_instance_name     = "OnDemandB"
  public_subnet_id            = "${var.public2_subnet_id}"
  private_subnet_id           = "${var.private2_subnet_id}"
  enable_public_ips           = "${var.enable_public_ips}"
  api_termination_protection  = "${var.api_termination_protection}"
  security_group_ids          = "${var.security_group_ids}"
}

