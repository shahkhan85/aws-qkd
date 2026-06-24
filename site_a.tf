### SITE A ###

module "site_a" {
  source = "./modules/site"

  name_prefix  = var.name_prefix
  site_name    = "site-a"
  global_tags  = var.global_tags
  ssh_key_name = var.ssh_key_name

  # Networking
  vpc_cidr            = var.site_a_vpc_cidr
  az                  = var.site_a_az
  mgmt_subnet_cidr    = local.site_a_subnets.mgmt
  untrust_subnet_cidr = local.site_a_subnets.untrust
  trust_subnet_cidr   = local.site_a_subnets.trust
  allowed_mgmt_cidrs  = var.allowed_mgmt_cidrs

  # VM-Series
  vmseries_version       = var.vmseries_version
  vmseries_instance_type = var.vmseries_instance_type
}
