output "username" {
  value = "admin"
}

output "password" {
  value = "${module.fgcp-ha.fgt1_id}"
}

output "cluster_login_url" {
  value = "https://${module.fgcp-ha.cluster_eip_public_ip}"
}

output "fgt1_login_url" {
  value = "https://${module.fgcp-ha.fgt1_hamgmt_eip_public_ip}"
}

output "fgt2_login_url" {
  value = "https://${module.fgcp-ha.fgt2_hamgmt_eip_public_ip}"
}