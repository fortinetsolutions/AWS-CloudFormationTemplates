resource "aws_cloudwatch_metric_alarm" "asg1-cpu-alarm-high" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-cpu-alarm-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_high}"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scaleout-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "asg1-cpu-alarm-low" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-cpu-alarm-low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_low}"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scalein-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "asg1-memory-alarm-high" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-memory-alarm-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_high}"
  alarm_description         = "This metric monitors ec2 memory utilization"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scaleout-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "asg1-memory-alarm-low" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-memory-alarm-low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_low}"
  alarm_description         = "This metric monitors ec2 memory utilization"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scalein-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "asg1-concurrent-sessions-alarm-high" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-concurrent-sessions-alarm-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "ConcurrentSessions"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_high}"
  alarm_description         = "This metric monitors ec2 concurrent sessions utilization"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scaleout-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "asg1-concurrent-sessions-alarm-low" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-concurrent-sessions-alarm-low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "ConcurrentSessions"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_low}"
  alarm_description         = "This metric monitors ec2 concurrent sessions utilization"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scalein-policy.arn}" ]
  insufficient_data_actions = []
}


resource "aws_cloudwatch_metric_alarm" "asg1-session-rate-high" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-session-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "SessionSetupRate"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_high}"
  alarm_description         = "This metric monitors ec2 session setup rate"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scaleout-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "asg1-session-rate-low" {
  alarm_name                = "${var.customer_prefix}-${var.environment}-concurrent-session-alarm-low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "SessionSetupRate"
  namespace                 = "AWS/EC2"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.threshold_low}"
  alarm_description         = "This metric monitors ec2 session setup rate"
  alarm_actions             = [ "${aws_autoscaling_policy.asg1-scalein-policy.arn}" ]
  insufficient_data_actions = []
}

resource "aws_autoscaling_policy" "asg1-scalein-policy" {
  name                   = "${var.customer_prefix}-${var.environment}-asg1-scalein-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg1.name}"
}

resource "aws_autoscaling_policy" "asg1-scaleout-policy" {
  name                   = "${var.customer_prefix}-${var.environment}-asg1-scaleout-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg1.name}"
}

resource "aws_launch_configuration" "fgtod_asg" {
  name_prefix   = "${var.customer_prefix}-${var.environment}-fgtod-lc"
  image_id      = "${lookup(var.fortigate-od-amis, var.aws_region)}"
  instance_type = "${var.fgt_instance_type}"
  security_groups = [ "${var.security_group_ids}" ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg1" {
  name                    = "${var.customer_prefix}-${var.environment}-asg1"
  depends_on              = [ "aws_iam_role.FortigateRole" ]
  launch_configuration    = "${aws_launch_configuration.fgtod_asg.name}"
  min_size                = "${var.asg1_min_size}"
  max_size                = "${var.asg1_max_size}"
  desired_capacity        = "${var.asg1_desired_size}"
  termination_policies    = [ "NewestInstance"]
  vpc_zone_identifier     = [ "${var.public1_subnet_id}", "${var.public2_subnet_id}" ]

  initial_lifecycle_hook {
    name                    = "${var.customer_prefix}-${var.environment}-lch"
    default_result          = "CONTINUE"
    heartbeat_timeout       = 2000
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_target_arn = "${var.sqs_target_arn}"
    role_arn                = "${aws_iam_role.FortigateRole.arn}"
  }

  tag {
    key                 = "Name"
    value               = "${var.customer_prefix}-${var.environment}-fgtod-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}