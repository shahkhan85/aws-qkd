### SECURITY VPC ###

module "vpc" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/vpc?ref=main"

  name                    = "${var.name_prefix}${var.site_name}-vpc"
  create_vpc              = true
  cidr_block              = var.vpc_cidr
  create_internet_gateway = true
  name_internet_gateway   = "${var.name_prefix}${var.site_name}-igw"
  enable_dns_hostnames    = true
  enable_dns_support      = true
  global_tags             = var.global_tags

  security_groups = {
    vmseries_mgmt = {
      name = "${var.name_prefix}${var.site_name}-vmseries-mgmt"
      rules = {
        all_outbound = {
          description = "Permit all outbound traffic"
          type        = "egress"
          from_port   = "0"
          to_port     = "0"
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ssh_inbound = {
          description = "Permit SSH for management"
          type        = "ingress"
          from_port   = "22"
          to_port     = "22"
          protocol    = "tcp"
          cidr_blocks = var.allowed_mgmt_cidrs
        }
        https_inbound = {
          description = "Permit HTTPS for management"
          type        = "ingress"
          from_port   = "443"
          to_port     = "443"
          protocol    = "tcp"
          cidr_blocks = var.allowed_mgmt_cidrs
        }
        etsi_qkd_inbound = {
          description = "Permit ETSI QKD 014 API from QKD KME devices on mgmt subnet"
          type        = "ingress"
          from_port   = "443"
          to_port     = "443"
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_subnet_cidr]
        }
      }
    }
    vmseries_untrust = {
      name = "${var.name_prefix}${var.site_name}-vmseries-untrust"
      rules = {
        all_outbound = {
          description = "Permit all outbound traffic"
          type        = "egress"
          from_port   = "0"
          to_port     = "0"
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ike_inbound = {
          description = "Permit IKE (UDP 500) for IPsec"
          type        = "ingress"
          from_port   = "500"
          to_port     = "500"
          protocol    = "udp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ike_nat_t_inbound = {
          description = "Permit IKE NAT-T (UDP 4500) for IPsec"
          type        = "ingress"
          from_port   = "4500"
          to_port     = "4500"
          protocol    = "udp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ipsec_esp_inbound = {
          description = "Permit ESP (protocol 50) for IPsec"
          type        = "ingress"
          from_port   = "0"
          to_port     = "0"
          protocol    = "50"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    vmseries_trust = {
      name = "${var.name_prefix}${var.site_name}-vmseries-trust"
      rules = {
        all_outbound = {
          description = "Permit all outbound traffic"
          type        = "egress"
          from_port   = "0"
          to_port     = "0"
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        all_inbound = {
          description = "Permit all inbound traffic from VPC"
          type        = "ingress"
          from_port   = "0"
          to_port     = "0"
          protocol    = "-1"
          cidr_blocks = [var.vpc_cidr]
        }
      }
    }
  }
}

### SUBNETS ###

module "subnet_mgmt" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/subnet_set?ref=main"

  name   = "${var.name_prefix}${var.site_name}-mgmt"
  vpc_id = module.vpc.id
  cidrs = {
    "${var.mgmt_subnet_cidr}" = {
      az   = var.az
      name = "${var.name_prefix}${var.site_name}-mgmt"
    }
  }
  global_tags = var.global_tags
}

module "subnet_untrust" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/subnet_set?ref=main"

  name   = "${var.name_prefix}${var.site_name}-untrust"
  vpc_id = module.vpc.id
  cidrs = {
    "${var.untrust_subnet_cidr}" = {
      az   = var.az
      name = "${var.name_prefix}${var.site_name}-untrust"
    }
  }
  global_tags = var.global_tags
}

module "subnet_trust" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/subnet_set?ref=main"

  name   = "${var.name_prefix}${var.site_name}-trust"
  vpc_id = module.vpc.id
  cidrs = {
    "${var.trust_subnet_cidr}" = {
      az   = var.az
      name = "${var.name_prefix}${var.site_name}-trust"
    }
  }
  global_tags = var.global_tags
}

### NAT GATEWAY (on mgmt subnet for outbound: bootstrap S3, KME API, updates) ###

module "natgw" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/nat_gateway_set?ref=main"

  subnets = module.subnet_mgmt.subnets
  nat_gateway_names = {
    "${var.az}" = "${var.name_prefix}${var.site_name}-natgw"
  }
  global_tags = var.global_tags
}

### ROUTES ###

# Management subnet: default route via NAT Gateway (for S3 bootstrap, KME API, updates)
resource "aws_route" "mgmt_default" {
  for_each = module.subnet_mgmt.unique_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.natgw.next_hop_set.ids[var.az]
}

# Untrust subnet: default route via IGW (for EIP-based IPsec tunnel endpoints)
resource "aws_route" "untrust_default" {
  for_each = module.subnet_untrust.unique_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.internet_gateway.id
}
