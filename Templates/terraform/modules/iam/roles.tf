terraform {
  required_version = ">= 0.8, <= 0.9.11"
}


resource "aws_iam_role" "WorkerRole" {
  name = "${var.role_name}"
  description = "${var.role_description}"
  path = "${var.role_path}"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
POLICY
}
