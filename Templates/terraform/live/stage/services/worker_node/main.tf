terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "worker_node" {

  source = "../../../../modules/services/worker_node"

  aws_region		            = "${var.aws_region}"
  environment                   = "${var.environment}"
  customer_prefix               = "${var.customer_prefix}"
  aws_wn_amis                   = "${lookup(var.worker-amis, var.aws_region)}"
  worker_node_instance_type     = "${var.worker_node_instance_type}"
  availability_zone             = "${var.availability_zone}"
  api_termination_protection    = "${var.api_termination_protection}"
  worker_node_instance_name     = "ASInstance"
  public_subnet_id              = "${var.public1_subnet_id}"
  enable_public_ips             = "${var.enable_public_ips}"
  security_group_ids            = "${var.security_group_ids}"
  instance_profile              = "${aws_iam_instance_profile.worker_node_profile.name}"
  key_name                      = "${var.key_name}"
}
