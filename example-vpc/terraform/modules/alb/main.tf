provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

resource "aws_lb" "public_alb" {
  name = "${var.customer_prefix}-${var.environment}"
  internal = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "application"
  subnets = ["${var.subnet1_id}", "${var.subnet2_id}"]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = "${aws_lb.public_alb.arn}"
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name = "${var.customer_prefix}-${var.environment}-alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = "${var.vpc_id}"
  health_check {
    protocol = "HTTP"
    port = "80"
  }
}
