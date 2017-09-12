terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

resource "aws_s3_bucket" "s3_bucket" {
  region    = "${var.aws_region}"
  bucket    = "${var.bucket}"
  acl       = "${var.acl}"

  tags {
    Name        = "${var.bucket}"
    Environment = "${var.environment}"
  }
}
