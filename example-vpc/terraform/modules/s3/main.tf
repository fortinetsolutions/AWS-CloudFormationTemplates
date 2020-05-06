
provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

resource "aws_s3_bucket" "s3_bucket" {
  region    = "${var.aws_region}"
  bucket    = "${var.bucket}"
  acl       = "${var.acl}"

  tags {
    Name        = "${var.bucket}"
    Customer    = "${var.customer_prefix}-${var.environment}"
  }
}
