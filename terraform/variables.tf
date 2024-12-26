# https://nicmx.github.io/Jool/en/usr-flags-global.html#logging-debug
variable "jool_logging_debug" {
  description = "Output Jool's debug logs"
  type        = bool
  default     = false
}

# https://nicmx.github.io/Jool/en/usr-flags-global.html#logging-bib
variable "jool_logging_bib" {
  description = "Output transport addresses mapped by Jool"
  type        = bool
  default     = true
}

# https://nicmx.github.io/Jool/en/usr-flags-global.html#logging-session
variable "jool_logging_session" {
  description = "Output every Jool session"
  type        = bool
  default     = false
}

variable "ami_name" {
  description = "Name filter to select AMI"
  type        = string
  default     = "fck-nat64-al2023-hvm-*-arm64-ebs"
}

variable "instance_type" {
  description = "EC2 instance type to build"
  type        = string
  default     = "t4g.nano"
}

variable "resource_name" {
  description = "Name to use for all resources created"
  type        = string
  default     = "fck-nat64"
}

variable "ssh_key_name" {
  description = "SSH key to attach to instance"
  type        = string
  default     = null
}

variable "disable_api_stop" {
  description = "Whether to block API requests to stop instance"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Whether to block API requests to terminate instance"
  type        = bool
  default     = false
}

variable "ebs_size" {
  description = "Size (GB) of EC2 instance's EBS volume"
  type        = number
  default     = 30
}

variable "ebs_kms_key" {
  description = "ID of KMS key to encrypt EC2 instance's EBS volume with"
  type        = string
  default     = null
}

variable "ebs_delete_on_termination" {
  description = "Whether to delete EBS volume on EC2 instance termination"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "ID of subet to create resources in"
  type        = string
}

variable "route_table_ids" {
  description = "List of route tables to update"
  type        = list(string)
}
