provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_ssm_parameter" "fgt_password" {
  name = "/${var.customer_prefix}/${var.environment}/${var.fgt_password_parameter_name}"
}

resource "aws_eip" "EIP" {
  count                 = var.enable_public_ips
  vpc                   = true
  network_interface     = aws_network_interface.public_eni.id
  tags = {
    Name            = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}"
    Environment     = "${var.environment}"
  }
}

data "template_file" "fgt_userdata" {
  template = "${file("${path.module}/fgt-userdata.tpl")}"

  vars = {
    fgt_byol_license   = "${file("${path.module}/${var.fgt_byol_license}")}"
    fgt_id             = "fgt-${var.customer_prefix}-${var.environment}-${var.availability_zone}"
    fgt_admin_password = "${data.aws_ssm_parameter.fgt_password.value}"
  }
}

resource "aws_network_interface" "public_eni" {
  subnet_id                   = var.public_subnet_id
  private_ips                 = ["${var.public_ip_address}"]
  security_groups             = [ "${var.security_group_public_id}" ]
  source_dest_check           = false

  tags = {
    Name = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}-ENI_Public"
  }
}

resource "aws_network_interface" "private_eni" {
  subnet_id                   = var.private_subnet_id
  private_ips                 = ["${var.private_ip_address}"]
  security_groups             = [ "${var.security_group_private_id}" ]
  source_dest_check           = false

  tags = {
    Name = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}-ENI_Private"
  }
}

resource "aws_instance" "fortigate" {

  ami                         = var.aws_fgtbyol_ami
  instance_type               = var.fgt_instance_type
  availability_zone           = var.availability_zone
  key_name                    = var.keypair
  user_data                  = data.template_file.fgt_userdata.rendered
  network_interface {
    device_index = 0
    network_interface_id   = aws_network_interface.public_eni.id
  }
  network_interface {
    device_index = 1
    network_interface_id   = aws_network_interface.private_eni.id
  }
  tags = {
    Name            = "${var.customer_prefix}-${var.environment}-${var.fortigate_instance_name}"
    Environment     = "${var.environment}"
  }
}

