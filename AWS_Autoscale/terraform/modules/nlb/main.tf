provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

resource "aws_lb" "public_nlb" {
  name = "${var.customer_prefix}-${var.environment}"
  internal = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  subnets = ["${var.subnet1_id}", "${var.subnet2_id}"]
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = "${aws_lb.public_nlb.arn}"
  port = "80"
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.nlb_target_group.arn}"
  }
}

resource "aws_lb_target_group" "nlb_target_group" {
  name = "${var.customer_prefix}-${var.environment}-nlb-tg"
  port = 80
  protocol = "TCP"
  vpc_id = "${var.vpc_id}"
  health_check {
    protocol = "TCP"
    port = "541"
  }
}
