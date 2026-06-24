output "vpc_id" {
  description = "ID of the security VPC"
  value       = module.vpc.id
}

output "fw_mgmt_public_ip" {
  description = "VM-Series management interface public IP (for SSH/HTTPS access)"
  value       = module.vmseries.public_ips["mgmt"]
}

output "fw_untrust_public_ip" {
  description = "VM-Series untrust interface public IP (IPsec tunnel endpoint)"
  value       = module.vmseries.public_ips["untrust"]
}

output "fw_instance_id" {
  description = "EC2 instance ID of the VM-Series firewall"
  value       = module.vmseries.instance.id
}

output "mgmt_subnet_id" {
  description = "Management subnet ID (QKD KME devices connect here)"
  value       = module.subnet_mgmt.subnets[var.az].id
}

output "trust_subnet_id" {
  description = "Trust subnet ID"
  value       = module.subnet_trust.subnets[var.az].id
}

output "untrust_subnet_id" {
  description = "Untrust subnet ID"
  value       = module.subnet_untrust.subnets[var.az].id
}

output "mgmt_security_group_id" {
  description = "Security group ID for management subnet"
  value       = module.vpc.security_group_ids["vmseries_mgmt"]
}
