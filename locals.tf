locals {
  # Subnet CIDR derivation from VPC CIDR
  # Given a /16 VPC CIDR (e.g., 10.100.0.0/16), we derive /24 subnets:
  #   mgmt:    x.x.0.0/24
  #   untrust: x.x.1.0/24
  #   trust:   x.x.2.0/24

  site_a_subnets = {
    mgmt    = cidrsubnet(var.site_a_vpc_cidr, 8, 0) # 10.100.0.0/24
    untrust = cidrsubnet(var.site_a_vpc_cidr, 8, 1) # 10.100.1.0/24
    trust   = cidrsubnet(var.site_a_vpc_cidr, 8, 2) # 10.100.2.0/24
  }

  site_b_subnets = {
    mgmt    = cidrsubnet(var.site_b_vpc_cidr, 8, 0) # 10.200.0.0/24
    untrust = cidrsubnet(var.site_b_vpc_cidr, 8, 1) # 10.200.1.0/24
    trust   = cidrsubnet(var.site_b_vpc_cidr, 8, 2) # 10.200.2.0/24
  }
}
