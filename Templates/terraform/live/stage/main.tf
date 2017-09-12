terraform {
  required_version = ">= 0.8, <= 0.9.11"
}


provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

module "ec2od" {
  source = "services/fgtod"

  aws_region                  = "${var.aws_region}"
  environment                 = "${var.environment}"
  customer_prefix             = "${var.customer_prefix}"
  fgt_instance_type           = "m3.large"
  availability_zone_1         = "${var.aws_region}a"
  availability_zone_2         = "${var.aws_region}c"
  public1_subnet_id           = "${module.vpc.public1_subnet_id}"
  private1_subnet_id          = "${module.vpc.private1_subnet_id}"
  public2_subnet_id           = "${module.vpc.public2_subnet_id}"
  private2_subnet_id          = "${module.vpc.private2_subnet_id}"
  security_group_ids          = "${module.vpc.fortigate_security_group_id}"
  asg1_min_size               = "${var.asg1_min_size}"
  asg1_max_size               = "${var.asg1_max_size}"
  asg1_desired_size           = "${var.asg1_desired_size}"
  sqs_target_arn              = "${module.sqs.sqs_target_arn}"
  scaling_period              = "${var.scaling_period}"
  threshold_high              = "${var.threshold_high}"
  threshold_low               = "${var.threshold_low}"
  enable_public_ips           = true
  api_termination_protection  = false
}

module "worker_node" {
  source = "services/worker_node"

  aws_region                  = "${var.aws_region}"
  environment                 = "${var.environment}"
  customer_prefix             = "${var.customer_prefix}"
  worker_node_instance_type   = "t2.micro"
  availability_zone           = "${var.aws_region}a"
  public1_subnet_id           = "${module.vpc.public1_subnet_id}"
  security_group_ids          = "${module.vpc.worker_node_security_group}"
  asg2_min_size               = "${var.asg2_min_size}"
  asg2_max_size               = "${var.asg2_max_size}"
  asg2_desired_size           = "${var.asg2_desired_size}"
  enable_public_ips           = true
  api_termination_protection  = false
}

module "vpc" {
  source = "vpc"

  aws_region                = "${var.aws_region}"
  environment               = "${var.environment}"
  customer_prefix           = "${var.customer_prefix}"
  instance_id_a             = "${module.ec2od.instance_id_a}"
  instance_id_b             = "${module.ec2od.instance_id_b}"
  private_interface_id_a    = "${module.ec2od.network_private_interface_id_a}"
  private_interface_id_b    = "${module.ec2od.network_private_interface_id_b}"
  avalability_zone_1        = "${var.aws_region}a"
  avalability_zone_2        = "${var.aws_region}c"
}

module "iam" {
  source = "iam"

  aws_region      = "${var.aws_region}"
  environment     = "${var.environment}"
  customer_prefix = "${var.customer_prefix}"
  acl             = "${var.acl}"

}

module "sqs" {
  source = "messaging/sqs"

  aws_region      = "${var.aws_region}"
  environment     = "${var.environment}"
  customer_prefix = "${var.customer_prefix}"

}

module "s3" {

  source = "data-stores/s3"

  aws_region      = "${var.aws_region}"
  environment     = "${var.environment}"
  customer_prefix = "${var.customer_prefix}"
  acl             = "${var.acl}"
  bucket          = "${var.customer_prefix}-${var.environment}-fgtasg"

}

module "elb" {
  source = "services/elb"

  aws_region                = "${var.aws_region}"
  environment               = "${var.environment}"
  customer_prefix           = "${var.customer_prefix}"
  elb_target                = "${var.elb_target}"
  ilb_target                = "${var.ilb_target}"
  availability_zone_1       = "${var.aws_region}a"
  availability_zone_2       = "${var.aws_region}c"
  log_bucket                = "${module.s3.asg-id}"
  public1_subnet_id         = "${module.vpc.public1_subnet_id}"
  public2_subnet_id         = "${module.vpc.public2_subnet_id}"
  private1_subnet_id        = "${module.vpc.private1_subnet_id}"
  private2_subnet_id        = "${module.vpc.private2_subnet_id}"
}
