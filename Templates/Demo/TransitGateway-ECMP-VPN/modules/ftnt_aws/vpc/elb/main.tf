resource "aws_lb" "public_nlb" {
  count = "${var.public_elb_type == "nlb" ? 1 : 0}"
  name = "${var.tag_name_prefix}-${var.tag_name_unique}"
  internal = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  subnets = ["${var.public_subnet1_id}", "${var.public_subnet2_id}"]
}

resource "aws_lb_listener" "nlb_listener" {
  count = "${var.public_elb_type == "nlb" ? 1 : 0}"
  load_balancer_arn = "${aws_lb.public_nlb.arn}"
  port = "80"
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.nlb_target_group.arn}"
  }
}

resource "aws_lb_target_group" "nlb_target_group" {
  count = "${var.public_elb_type == "nlb" ? 1 : 0}"
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-target-group"
  port = 80
  protocol = "TCP"
  vpc_id = "${var.vpc_id}"
  health_check {
    protocol = "TCP"
    port = "541"
  }
}

resource "aws_lb_target_group_attachment" "nlb_target_group_attachment1" {
  count = "${var.public_elb_type == "nlb" ? 1 : 0}"
  target_group_arn = "${aws_lb_target_group.nlb_target_group.arn}"
  target_id = "${var.fgt1_id}"
}

resource "aws_lb_target_group_attachment" "nlb_target_group_attachment2" {
  count = "${var.public_elb_type == "nlb" ? 1 : 0}"
  target_group_arn = "${aws_lb_target_group.nlb_target_group.arn}"
  target_id = "${var.fgt2_id}"
}

resource "aws_lb" "public_alb" {
  count = "${var.public_elb_type == "alb" ? 1 : 0}"
  name = "${var.tag_name_prefix}-${var.tag_name_unique}"
  internal = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_secgrp.id}"]
  subnets = ["${var.public_subnet1_id}", "${var.public_subnet2_id}"]
}

resource "aws_lb_listener" "alb_listener" {
  count = "${var.public_elb_type == "alb" ? 1 : 0}"
  load_balancer_arn = "${aws_lb.public_alb.arn}"
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  count = "${var.public_elb_type == "alb" ? 1 : 0}"
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = "${var.vpc_id}"
  health_check {
    protocol = "HTTPS"
    port = "443"
    path = "/login"
    matcher = "200"
  }
}

resource "aws_security_group" "alb_secgrp" {
  count = "${var.public_elb_type == "alb" ? 1 : 0}"
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-secgrp"
  description = "secgrp"
  vpc_id = "${var.vpc_id}"
  ingress {
    description = "Allow HTTP to ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-secgrp"
  }
}

resource "aws_lb_target_group_attachment" "alb_target_group_attachment1" {
  count = "${var.public_elb_type == "alb" ? 1 : 0}"
  target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
  target_id = "${var.fgt1_id}"
}

resource "aws_lb_target_group_attachment" "alb_target_group_attachment2" {
  count = "${var.public_elb_type == "alb" ? 1 : 0}"
  target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
  target_id = "${var.fgt2_id}"
}