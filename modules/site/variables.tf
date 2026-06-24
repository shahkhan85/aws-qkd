### GENERAL ###

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "site_name" {
  description = "Site identifier (e.g., 'site-a', 'site-b')"
  type        = string
}

variable "global_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

### NETWORKING ###

variable "vpc_cidr" {
  description = "CIDR block for the security VPC"
  type        = string
}

variable "az" {
  description = "Availability zone for this site"
  type        = string
}

variable "mgmt_subnet_cidr" {
  description = "CIDR for the management subnet"
  type        = string
}

variable "untrust_subnet_cidr" {
  description = "CIDR for the untrust (public) subnet"
  type        = string
}

variable "trust_subnet_cidr" {
  description = "CIDR for the trust (private) subnet"
  type        = string
}

variable "allowed_mgmt_cidrs" {
  description = "CIDR blocks allowed to access management interface (SSH/HTTPS)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

### VM-SERIES ###

variable "vmseries_version" {
  description = "PAN-OS version for VM-Series (12.1+ required for QKD)"
  type        = string
  default     = "12.1.1"
}

variable "vmseries_instance_type" {
  description = "EC2 instance type for VM-Series"
  type        = string
  default     = "m5.xlarge"
}

### BOOTSTRAP ###

variable "bootstrap_options" {
  description = "Additional bootstrap options for VM-Series init-cfg.txt"
  type        = map(string)
  default     = {}
}
