# QKD-Secured Site-to-Site VPN on AWS

Terraform reference architecture for deploying **Quantum Key Distribution (QKD)-secured IPsec VPN tunnels** using Palo Alto Networks VM-Series firewalls on AWS.

## Architecture

```
  Security VPC A (10.100.0.0/16)              Security VPC B (10.200.0.0/16)

  ┌──────────────────┐  IPsec Tunnel   ┌──────────────────┐
  │ VM-Series FW A   │◄═══(QKD)═══════►│ VM-Series FW B   │
  │ eth0: mgmt (EIP) │  untrust-to-    │ eth0: mgmt (EIP) │
  │ eth1: untrust(EIP│  untrust        │ eth1: untrust(EIP│
  │ eth2: trust      │                 │ eth2: trust      │
  └────────┬─────────┘                 └────────┬─────────┘
           │ mTLS (ETSI 014)                    │ mTLS (ETSI 014)
  ┌────────▼─────────┐                 ┌────────▼─────────┐
  │ QKD Device A     │◄╌╌quantum╌╌╌╌╌►│ QKD Device B     │
  │ (KME) on mgmt   │  dark fiber     │ (KME) on mgmt   │
  └──────────────────┘                 └──────────────────┘
```

Two security VPCs in the same AWS region, each containing:
- **VM-Series firewall** (PAN-OS 12.1+) with 3 interfaces (mgmt, untrust, trust)
- **QKD KME device** on the management subnet, providing quantum-derived keys via ETSI QKD 014 API

The IPsec tunnel runs between the untrust EIPs. QKD devices exchange keys over dedicated dark fiber (quantum + classical channels).

## Prerequisites

- AWS account with permissions to create VPCs, EC2 instances, S3 buckets, IAM roles
- Terraform >= 1.5
- EC2 key pair in your target region
- VM-Series BYOL license (PAN-OS 12.1+)
- QKD devices (e.g., IDQuantique Clavis XG) with dark fiber between sites

## Quick Start

1. **Clone and configure:**
   ```bash
   cd aws-qkd
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Outputs:**
   - `site_a_fw_mgmt_ip` / `site_b_fw_mgmt_ip` — SSH/HTTPS to manage firewalls
   - `site_a_fw_untrust_ip` / `site_b_fw_untrust_ip` — IPsec tunnel endpoint IPs
   - `site_a_mgmt_subnet_id` / `site_b_mgmt_subnet_id` — Connect QKD KME devices here

4. **Post-deploy (manual):**
   - Connect QKD KME devices to each site's management subnet
   - Configure QKD profiles on each VM-Series (see `docs/qkd_integration_guide.md`)
   - Configure IKE gateway with QKD profile and peer untrust EIP
   - Establish IPsec tunnel

## File Structure

```
aws-qkd/
├── versions.tf              # Terraform & provider versions
├── variables.tf             # Input variables
├── locals.tf                # Computed subnet CIDRs
├── site_a.tf                # Site A deployment
├── site_b.tf                # Site B deployment
├── outputs.tf               # Tunnel endpoints, mgmt IPs
├── terraform.tfvars.example # Example configuration
├── modules/
│   └── site/                # Reusable per-site module
│       ├── main.tf          # Module metadata
│       ├── variables.tf     # Site inputs
│       ├── outputs.tf       # Site outputs
│       ├── vpc.tf           # VPC, subnets, SGs, NAT GW, routes
│       ├── firewall.tf      # VM-Series instance (3 ENIs)
│       └── bootstrap.tf     # S3 bootstrap + IAM
└── docs/
    ├── architecture.md      # Detailed design
    └── qkd_integration_guide.md  # Post-deploy QKD setup
```

## Upstream Modules

Uses [PaloAltoNetworks/terraform-aws-swfw-modules](https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules):
- `vpc` — VPC with security groups
- `subnet_set` — Subnets with route tables
- `vmseries` — VM-Series EC2 instance
- `bootstrap` — S3 bootstrap bucket + IAM

## Security Groups

| Group | Inbound Rules |
|-------|--------------|
| **mgmt** | SSH (22), HTTPS (443) from allowed CIDRs; HTTPS (443) from mgmt subnet (KME API). Routes via IGW (EIP on mgmt ENI). |
| **untrust** | IKE (UDP 500), NAT-T (UDP 4500), ESP (protocol 50) — for IPsec. Routes via IGW. |
| **trust** | All traffic from VPC CIDR. No default route (local only). |
