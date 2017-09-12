resource "aws_launch_configuration" "worker_node_asg" {
  name_prefix   = "${var.customer_prefix}-${var.environment}-worker-node-lc"
  image_id      = "${lookup(var.worker-amis, var.aws_region)}"
  instance_type = "${var.worker_node_instance_type}"
  security_groups = [ "${var.security_group_ids}" ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg1" {
  name                  = "${var.customer_prefix}-${var.environment}-asg2"
  launch_configuration  = "${aws_launch_configuration.worker_node_asg.name}"
  min_size              = "${var.asg2_min_size}"
  max_size              = "${var.asg2_max_size}"
  desired_capacity      = "${var.asg2_desired_size}"
  termination_policies  = [ "NewestInstance"]
  vpc_zone_identifier   = [ "${var.public1_subnet_id}" ]

  lifecycle {
    create_before_destroy = true
  }
}
