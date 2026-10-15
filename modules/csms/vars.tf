variable "region" {
  description = "Huawei Cloud region to create the secrets in. If omitted, the provider-level region is used."
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of secrets to create in CSMS, keyed by a name you choose for tracking. Each value becomes a plain-text CSMS secret — pass the whole map as sensitive from the caller."
  type = map(object({
    name        = optional(string) # defaults to the map key if omitted — this is the CSMS secret NAME that CCE's SecretProviderClass objectName must match
    secret_text = string
    description = optional(string, "Managed by Terraform")
    kms_key_id  = optional(string) # defaults to CSMS's own "csms/default" key if omitted
  }))
  sensitive = true
}

variable "enterprise_project_id" {
  description = "Optional enterprise project ID to associate the secrets with."
  type        = string
  default     = null
}

variable "tags" {
  description = "Key-value tags applied to every secret in var.secrets."
  type        = map(string)
  default     = {}
}
