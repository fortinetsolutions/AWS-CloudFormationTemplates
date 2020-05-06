provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

data "template_file" "web_userdata" {
  template = "${file("${var.userdata}")}"
}

resource "aws_iam_role" "asg-endpoint-role" {

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "asg-policy" {
  name = "${var.customer_prefix}-${var.environment}-asg-endpoint-policy"
  role = "${aws_iam_role.asg-endpoint-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_launch_configuration" "asg_launch" {
  name                        = "${var.customer_prefix}-${var.environment}-endpoint-lconf"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${var.security_group}"]
}

resource "aws_autoscaling_group" "asg" {
  name                    = "${var.customer_prefix}-${var.environment}-endpoint"
  max_size                = "${var.max_size}"
  min_size                = "${var.min_size}"
  desired_capacity        = "${var.desired}"
  vpc_zone_identifier     = ["${var.private1_subnet_id}", "${var.private2_subnet_id}"]
  launch_configuration    = "${aws_launch_configuration.asg_launch.id}"
  termination_policies    = ["NewestInstance"]
  target_group_arns       = ["${var.target_group_arns}"]
  tags = [
    {
      key                 = "AutoScale Group Instance"
      value               = "${var.customer_prefix}-${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.customer_prefix}-${var.environment}-asg-instance"
      propagate_at_launch = true
    }
  ]
}

