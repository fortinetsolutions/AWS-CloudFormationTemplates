output "tgw_id" {
  value = "${aws_ec2_transit_gateway.transit_gateway.id}"
}

output "tgw_default_association_id" {
  value = "${aws_ec2_transit_gateway.transit_gateway.association_default_route_table_id}"
}

output "tgw_default_propagation_id" {
  value = "${aws_ec2_transit_gateway.transit_gateway.propagation_default_route_table_id}"
}

output "tgw_private_route_table_id" {
  value = "${aws_ec2_transit_gateway_route_table.transit_gateway_private_route_table.id}"
}