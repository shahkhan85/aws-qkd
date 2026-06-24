### SITE B ###

module "site_b" {
  source = "./modules/site"

  name_prefix  = var.name_prefix
  site_name    = "site-b"
  global_tags  = var.global_tags
  ssh_key_name = var.ssh_key_name

  # Networking
  vpc_cidr            = var.site_b_vpc_cidr
  az                  = var.site_b_az
  mgmt_subnet_cidr    = local.site_b_subnets.mgmt
  untrust_subnet_cidr = local.site_b_subnets.untrust
  trust_subnet_cidr   = local.site_b_subnets.trust
  allowed_mgmt_cidrs  = var.allowed_mgmt_cidrs

  # VM-Series
  vmseries_version       = var.vmseries_version
  vmseries_instance_type = var.vmseries_instance_type
}
