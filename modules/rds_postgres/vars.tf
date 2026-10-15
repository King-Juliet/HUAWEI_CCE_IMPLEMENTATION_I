variable "region" {
  description = "Huawei Cloud region to create the instance in. If omitted, the provider-level region is used."
  type        = string
  default     = null
}

variable "instance_name" {
  description = "RDS instance name. 4-64 chars: letters, digits, hyphens, underscores."
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC to create the instance in."
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing subnet for the instance's private network interface."
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group controlling access to the instance (e.g. allow 5432 only from the pod subnet)."
  type        = string
}

variable "availability_zone" {
  description = "List of AZ names. One entry = single instance. Two entries = Primary/Standby (HA) — the flavor must be an .ha flavor in that case."
  type        = list(string)
  default     = ["af-south-1a"]
}

variable "flavor" {
  description = "RDS flavor code, e.g. \"rds.pg.n1.large.2\" (single) or \"rds.pg.n1.large.2.ha\" (Primary/Standby). Confirm availability for af-south-1 via the huaweicloud_rds_flavors data source before applying — flavor availability is region/AZ specific."
  type        = string
}

variable "pg_version" {
  description = "PostgreSQL major version, e.g. \"14\"."
  type        = string
  default     = "14"
}

variable "admin_password" {
  description = "Password for the instance's default admin/superuser account. 8-32 chars, must include uppercase, lowercase, digits, and one of ~!@#%^*-_=+?. Pass as a sensitive value — see secrets.tf for how this repo sources it."
  type        = string
  sensitive   = true
}

variable "volume_type" {
  description = "Storage type: ULTRAHIGH, LOCALSSD, CLOUDSSD, or ESSD."
  type        = string
  default     = "ULTRAHIGH"
}

variable "volume_size" {
  description = "Storage size in GB. 40-4000, must be a multiple of 10."
  type        = number
  default     = 40
}

variable "backup_keep_days" {
  description = "Automated backup retention in days (0-732). 0 disables automated backups."
  type        = number
  default     = 7
}

variable "backup_start_time" {
  description = "Daily backup window, UTC, format \"hh:mm-HH:MM\" (must span exactly 1 hour)."
  type        = string
  default     = "02:00-03:00"
}

variable "ha_replication_mode" {
  description = "Replication mode when availability_zone has 2 entries (Primary/Standby): async or sync. Ignored for single-AZ instances."
  type        = string
  default     = "async"
}

variable "charging_mode" {
  description = "Billing mode: prePaid or postPaid."
  type        = string
  default     = "postPaid"
}

variable "parameters" {
  description = "Custom PostgreSQL parameter group overrides, as a list of {name, value} pairs, e.g. [{name = \"max_connections\", value = \"200\"}]."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "enterprise_project_id" {
  description = "Optional enterprise project ID to associate the instance with."
  type        = string
  default     = null
}

variable "tags" {
  description = "Key-value tags applied to the instance."
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "Map of application databases to create on the instance (beyond the default), keyed by a name you choose for tracking. Owner must be one of the accounts in var.accounts (created first)."
  type = map(object({
    name        = optional(string) # defaults to the map key if omitted
    owner       = string           # must match a key's `name` in var.accounts
    description = optional(string, "Managed by Terraform")
  }))
  default = {}
}

variable "accounts" {
  description = "Map of non-admin DB accounts (roles) to create on the instance, keyed by a name you choose for tracking. Pass passwords as sensitive values — see secrets.tf for how this repo sources them."
  type = map(object({
    name        = optional(string) # defaults to the map key if omitted
    password    = string
    description = optional(string, "Managed by Terraform")
  }))
  default   = {}
  sensitive = true
}
