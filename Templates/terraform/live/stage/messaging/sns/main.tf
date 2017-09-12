terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "sns" {

  source = "../../../../modules/messaging/sns"

  aws_region		= "${var.aws_region}"
  sns_topic	        = "dg-${var.environment}-sns-worker-topic"
  sns_subscription	= "dg-${var.environment}-sns-worker-subscription"
}

