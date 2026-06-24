### GENERAL ###

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-1"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "qkd-"
}

variable "global_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project = "qkd-vpn"
  }
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair for SSH access to VM-Series management"
  type        = string
}

variable "allowed_mgmt_cidrs" {
  description = "CIDR blocks allowed to access VM-Series management (SSH/HTTPS)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

### SITE A ###

variable "site_a_vpc_cidr" {
  description = "CIDR block for Site A security VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "site_a_az" {
  description = "Availability zone for Site A"
  type        = string
  default     = "us-west-1b"
}

### SITE B ###

variable "site_b_vpc_cidr" {
  description = "CIDR block for Site B security VPC"
  type        = string
  default     = "10.200.0.0/16"
}

variable "site_b_az" {
  description = "Availability zone for Site B"
  type        = string
  default     = "us-west-1c"
}

### VM-SERIES ###

variable "vmseries_version" {
  description = "PAN-OS version for VM-Series (must be 12.1+ for QKD support)"
  type        = string
  default     = "12.1.1"
}

variable "vmseries_instance_type" {
  description = "EC2 instance type for VM-Series"
  type        = string
  default     = "m5.xlarge"
}
