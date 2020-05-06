provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

data "template_file" "web_userdata" {
  template = "${file("${var.userdata}")}"
}

resource "aws_iam_role" "asg-role" {

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
  name = "${var.customer_prefix}-${var.environment}-asg-policy"
  role = "${aws_iam_role.asg-role.id}"
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
  name                        = "${var.customer_prefix}-${var.environment}-${var.asg_name}-fgt-lconf"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${var.security_group}"]
  associate_public_ip_address = true
  user_data = "${data.template_file.web_userdata.rendered}"
}

resource "aws_autoscaling_group" "asg" {
  name                    = "${var.customer_prefix}-${var.environment}-${var.asg_name}-fgt-asg"
  max_size                = "${var.max_size}"
  min_size                = "${var.min_size}"
  desired_capacity        = "${var.desired}"
  vpc_zone_identifier     = ["${var.public_subnet1_id}", "${var.public_subnet2_id}"]
  launch_configuration    = "${aws_launch_configuration.asg_launch.id}"
  termination_policies    = ["NewestInstance"]
  target_group_arns       = ["${var.target_group_arns}"]
  initial_lifecycle_hook {
      name                    = "${var.customer_prefix}-${var.environment}-fgt-launch-lch-${var.license}"
      default_result          = "ABANDON"
      heartbeat_timeout       = 600
      lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_target_arn = "${var.topic_arn}"
      role_arn                = "${aws_iam_role.asg-role.arn}"
      notification_metadata   = "${var.public_subnet1_id}:${var.private_subnet1_id}:${var.public_subnet2_id}:${var.private_subnet2_id}"
  }


  initial_lifecycle_hook {
      name                    = "${var.customer_prefix}-${var.environment}-fgt-terminate-lch-${var.license}"
      default_result          = "ABANDON"
      heartbeat_timeout       = 600
      lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_target_arn = "${var.topic_arn}"
      role_arn                = "${aws_iam_role.asg-role.arn}"
  }

  tags = [
    {
      key                 = "Fortigate-S3-License-Bucket"
      value               = "${var.s3_license_bucket}"
      propagate_at_launch = true
    },
    {
      key                 = "Fortigate-License"
      value               = "${var.license}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.customer_prefix}-${var.environment}-${var.license}-instance"
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_policy" "scale-in-policy" {
  name                   = "${var.customer_prefix}-${var.environment}-${var.asg_name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${var.monitored_asg_name == "" ? aws_autoscaling_group.asg.name : var.monitored_asg_name}"
}

resource "aws_autoscaling_policy" "scale-out-policy" {
  name                   = "${var.customer_prefix}-${var.environment}-${var.asg_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${var.monitored_asg_name == "" ? aws_autoscaling_group.asg.name : var.monitored_asg_name}"
}

resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name             = "${var.customer_prefix}-${var.environment}-${var.asg_name}-cpulo-alarm"
  comparison_operator    = "LessThanOrEqualToThreshold"
  evaluation_periods     = "1"
  metric_name            = "CPUUtilization"
  namespace              = "AWS/EC2"
  period                 = "300"
  statistic              = "Average"
  threshold              = "20"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }

  alarm_description      = "This metric monitors ec2 cpu utilization"
  alarm_actions          = ["${aws_autoscaling_policy.scale-in-policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = "${var.customer_prefix}-${var.environment}-${var.asg_name}-cpuhi-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-out-policy.arn}"]
}

resource "aws_autoscaling_notification" "asg-notification"{
  group_names            = ["${aws_autoscaling_group.asg.name}"]
  notifications          = [    "autoscaling:TEST_NOTIFICATION",
                                "autoscaling:EC2_INSTANCE_LAUNCH",
                                "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
                                "autoscaling:EC2_INSTANCE_TERMINATE",
                                "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]
  topic_arn              = "${var.topic_arn}"
}
