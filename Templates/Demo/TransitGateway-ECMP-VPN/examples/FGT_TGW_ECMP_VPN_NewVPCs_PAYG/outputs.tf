output "fgt_username" {
  value = "admin"
}

output "fgt1_password" {
  value = "${module.fgt1.fgt_id}"
}

output "fgt2_password" {
  value = "${module.fgt2.fgt_id}"
}

output "fgt1_login_url" {
  value = "https://${module.fgt1.fgt_public_ip}"
}

output "fgt2_login_url" {
  value = "https://${module.fgt2.fgt_public_ip}"
}

output "tgw_id" {
  value = "${module.transit-gw.tgw_id}"
}

output "tgw_default_association_id" {
  value = "${module.transit-gw.tgw_default_association_id}"
}

output "tgw_default_route_table_id" {
  value = "${module.transit-gw.tgw_default_propagation_id}"
}

output "tgw_private_route_table" {
  value = "${module.transit-gw.tgw_private_route_table_id}" 
}