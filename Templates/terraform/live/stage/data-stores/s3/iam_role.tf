data "aws_iam_policy_document" "s3-instance-assume-role-policy" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type        = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "BootFromS3Role" {
  name = "${var.aws_region}-${var.environment}-BootFromS3Role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.s3-instance-assume-role-policy.json}"
}
