### VM-SERIES FIREWALL ###

module "vmseries" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/vmseries?ref=main"

  name             = "${var.name_prefix}${var.site_name}-fw"
  vmseries_version = var.vmseries_version
  instance_type    = var.vmseries_instance_type
  ssh_key_name     = var.ssh_key_name
  tags             = var.global_tags

  interfaces = {
    mgmt = {
      device_index       = 0
      subnet_id          = module.subnet_mgmt.subnets[var.az].id
      name               = "${var.name_prefix}${var.site_name}-fw-mgmt"
      create_public_ip   = true
      source_dest_check  = true
      security_group_ids = [module.vpc.security_group_ids["vmseries_mgmt"]]
    }
    untrust = {
      device_index       = 1
      subnet_id          = module.subnet_untrust.subnets[var.az].id
      name               = "${var.name_prefix}${var.site_name}-fw-untrust"
      create_public_ip   = true
      source_dest_check  = false
      security_group_ids = [module.vpc.security_group_ids["vmseries_untrust"]]
    }
    trust = {
      device_index       = 2
      subnet_id          = module.subnet_trust.subnets[var.az].id
      name               = "${var.name_prefix}${var.site_name}-fw-trust"
      create_public_ip   = false
      source_dest_check  = false
      security_group_ids = [module.vpc.security_group_ids["vmseries_trust"]]
    }
  }

  bootstrap_options = join(";", compact([
    "vmseries-bootstrap-aws-s3bucket=${module.bootstrap.bucket_name}",
  ]))

  iam_instance_profile = module.bootstrap.instance_profile_name
}
