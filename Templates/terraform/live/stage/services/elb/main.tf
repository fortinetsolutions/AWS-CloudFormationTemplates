terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "elb" {

  source = "../../../../modules/services/elb"

  aws_region		      = "${var.aws_region}"
  environment             = "${var.environment}"
  customer_prefix         = "${var.customer_prefix}"
  elb_target              = "${var.elb_target}"
  ilb_target              = "${var.ilb_target}"
  public1_subnet_id       = "${var.public1_subnet_id}"
  public2_subnet_id       = "${var.public2_subnet_id}"
  private1_subnet_id      = "${var.private1_subnet_id}"
  private2_subnet_id      = "${var.private2_subnet_id}"
  availability_zone_1     = "${var.aws_region}a"
  availability_zone_2     = "${var.aws_region}b"
  log_bucket              = "${var.log_bucket}"
}
