
provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

module "function" {
  source = "modules/lambda"

  name         = "${var.lambda_name}"
  description  = "${var.lambda_description}"
  handler      = "${var.lambda_handler}"
  runtime      = "${var.runtime}"
  package_path = "${var.package_path}"
}

module "vpc" {
  source = "modules/vpc"

  aws_region                = "${var.aws_region}"
  environment               = "${var.environment}"
  customer_prefix           = "${var.customer_prefix}"
  avalability_zone_1        = "${var.aws_region}a"
  avalability_zone_2        = "${var.aws_region}c"
}

module "ec2od" {
  source = "modules/fortigate_paygo"

  aws_region                  = "${var.aws_region}"
  environment                 = "${var.environment}"
  customer_prefix             = "${var.customer_prefix}"
  fgt_instance_type           = "m3.large"
  availability_zone_1         = "${var.aws_region}a"
  availability_zone_2         = "${var.aws_region}c"
  fortigate_instance_name     = ""
  aws_fgtod_amis              = "${lookup(var.fortigate-od-amis, var.aws_region)}"
  public1_subnet_id           = "${module.vpc.public1_subnet_id}"
  private1_subnet_id          = "${module.vpc.private1_subnet_id}"
  public2_subnet_id           = "${module.vpc.public2_subnet_id}"
  private2_subnet_id          = "${module.vpc.private2_subnet_id}"
  security_group_ids          = "${module.vpc.fortigate_security_group_id}"
  asg1_min_size               = "${var.asg1_min_size}"
  asg1_max_size               = "${var.asg1_max_size}"
  asg1_desired_size           = "${var.asg1_desired_size}"
  scaling_period              = "${var.scaling_period}"
  threshold_high              = "${var.threshold_high}"
  threshold_low               = "${var.threshold_low}"
  enable_public_ips           = true
  api_termination_protection  = false
}
