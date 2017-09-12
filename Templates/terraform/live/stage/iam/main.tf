terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "iam" {

  source = "../../../modules/iam"

  customer_prefix     = "${var.customer_prefix}"
  policy_name         = "WorkerPolicy"
  policy_path         = "/"
  policy_description  = "Worker Node IAM Policy"

  role_name           = "WorkerRole"
  role_description    = "Worker Node Role Description"
  role_path           = "/"
}
