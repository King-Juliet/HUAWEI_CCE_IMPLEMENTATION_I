variable "region" {
  description = "Huawei Cloud region to create the organization/repositories in. If omitted, the provider-level region is used."
  type        = string
  default     = null
}

variable "organization_name" {
  description = "Name of the SWR organization (namespace) — must be globally unique across all of Huawei Cloud, not just your account."
  type        = string
}

variable "repositories" {
  description = "Map of repositories to create inside the organization, keyed by a name you choose for tracking."
  type = map(object({
    name        = optional(string) # defaults to the map key if omitted
    is_public   = optional(bool, false)
    description = optional(string, "Managed by Terraform")
    category    = optional(string, "other") # one of: app_server, linux, framework_app, database, lang, other, windows, arm
  }))
  default = {}
}
