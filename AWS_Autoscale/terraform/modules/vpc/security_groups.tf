resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "allow all traffic"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  tags {
    Name        = "DG ${var.environment} Allow All Security Group"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "ASSecurityGroup" {
  name = "ASSecurityGroup"
  description = "Allow only ssh     inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags {
    Name        = "DG ${var.environment} Worker Node Security Group"
    Environment = "${var.environment}"
  }
}
