### SITE A OUTPUTS ###

output "site_a_fw_mgmt_ip" {
  description = "Site A — VM-Series management public IP (SSH/HTTPS)"
  value       = module.site_a.fw_mgmt_public_ip
}

output "site_a_fw_untrust_ip" {
  description = "Site A — VM-Series untrust public IP (IPsec tunnel endpoint)"
  value       = module.site_a.fw_untrust_public_ip
}

output "site_a_vpc_id" {
  description = "Site A — Security VPC ID"
  value       = module.site_a.vpc_id
}

output "site_a_mgmt_subnet_id" {
  description = "Site A — Management subnet ID (connect QKD KME here)"
  value       = module.site_a.mgmt_subnet_id
}

### SITE B OUTPUTS ###

output "site_b_fw_mgmt_ip" {
  description = "Site B — VM-Series management public IP (SSH/HTTPS)"
  value       = module.site_b.fw_mgmt_public_ip
}

output "site_b_fw_untrust_ip" {
  description = "Site B — VM-Series untrust public IP (IPsec tunnel endpoint)"
  value       = module.site_b.fw_untrust_public_ip
}

output "site_b_vpc_id" {
  description = "Site B — Security VPC ID"
  value       = module.site_b.vpc_id
}

output "site_b_mgmt_subnet_id" {
  description = "Site B — Management subnet ID (connect QKD KME here)"
  value       = module.site_b.mgmt_subnet_id
}

### IPSEC TUNNEL INFO ###

output "ipsec_tunnel_endpoints" {
  description = "IPsec tunnel endpoint IPs — configure these as IKE gateway peer addresses"
  value = {
    site_a_untrust_eip = module.site_a.fw_untrust_public_ip
    site_b_untrust_eip = module.site_b.fw_untrust_public_ip
  }
}
