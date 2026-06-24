# Site Module
#
# Deploys a complete site for the QKD-secured VPN architecture:
#   - Security VPC with mgmt, untrust, and trust subnets
#   - VM-Series firewall (PAN-OS 12.1+) with 3 ENIs
#   - S3 bootstrap bucket with init-cfg.txt
#   - NAT Gateway on mgmt subnet for outbound access
#
# QKD KME devices connect to the mgmt subnet. The firewall
# communicates with the local KME via ETSI QKD 014 REST API
# over the management interface.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
  }
}
