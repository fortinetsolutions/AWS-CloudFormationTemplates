terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

module "sqs" {

  source = "../../../../modules/messaging/sqs"

  customer_prefix           = "${var.customer_prefix}"
  environment               = "${var.environment}"
  aws_region                = "${var.aws_region}"
  queue_name			    = "${var.customer_prefix}-${var.environment}-queue"
  receive_wait_time_seconds	= 20
}

resource "aws_sqs_queue_policy" "SQSPermission" {
  queue_url       = "${module.sqs.sqs_name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SQS:*",
      "Resource": "${module.sqs.sqs_arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${module.sqs.sqs_arn}"
        }
      }
    }
  ]
}
POLICY
}