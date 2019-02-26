resource "aws_ec2_transit_gateway" "transit_gateway" {
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  vpn_ecmp_support = "enable"
  dns_support = "enable"
  amazon_side_asn = "64512"
  tags {
    Name = "${var.tag_name_prefix}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "transit_gateway_private_route_table" {
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  tags {
    Name = "${var.tag_name_prefix}-private-tgw-rt"
  }
}