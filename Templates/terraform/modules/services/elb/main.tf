terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_elb" "external_elb" {
  name                = "${var.customer_prefix}-${var.aws_region}-${var.environment}-elb"
  subnets             = ["${var.public1_subnet_id}", "${var.public2_subnet_id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#  listener {
#    instance_port      = 8443
#    instance_protocol  = "http"
#    lb_port            = 443
#    lb_protocol        = "https"
#    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:${var.elb_target}/"
    interval            = 5
  }

  /*
  access_logs {
    bucket                = "${var.log_bucket}"
    bucket_prefix         = "${var.customer_prefix}/${var.environment}/elb"
    interval              = 60
    enabled               = true
  }
  */

  instances                   = []
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "${var.customer_prefix}-${var.aws_region}-${var.environment}-elb"
  }
}


resource "aws_elb" "internal_elb" {
  name                  = "${var.customer_prefix}-${var.aws_region}-${var.environment}-ilb"
  subnets               = ["${var.private1_subnet_id}", "${var.private2_subnet_id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#  listener {
#    instance_port      = 8443
#    instance_protocol  = "http"
#    lb_port            = 443
#    lb_protocol        = "https"
#    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:${var.ilb_target}/"
    interval            = 5
  }

  /*
  access_logs {
    bucket                = "${var.log_bucket}"
    bucket_prefix         = "${var.customer_prefix}/${var.environment}/ilb"
    interval              = 60
    enabled               = true
  }
  */

  instances                   = []
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "${var.customer_prefix}-${var.aws_region}-${var.environment}-ilb"
  }
}

