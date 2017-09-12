terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "s3asg" {

  source = "../../../../modules/data-stores/s3"

  aws_region		= "${var.aws_region}"
  bucket            = "${var.bucket}"
  acl               = "${var.acl}"
  environment       = "${var.environment}"
  customer_prefix   = "${var.customer_prefix}"
}
