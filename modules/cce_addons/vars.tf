variable "region" {
  description = "Huawei Cloud region to create the add-on(s) in. If omitted, the provider-level region is used."
  type        = string
  default     = null
}

variable "cluster_id" {
  description = "ID of the CCE Autopilot cluster to install add-ons into — this comes from the cluster module's `cluster_id` output."
  type        = string
}

variable "addons" {
  description = <<-EOT
    Map of add-ons to install, keyed by a name you choose for tracking (e.g. "logging", "dns", "monitoring").
    Each entry defines the actual Huawei add-on template to install and its config.

    IMPORTANT: the "values" map's expected keys/JSON shape are different for every add-on
    (log-agent, coredns, etc.) — confirm the correct structure from Huawei's add-on template
    docs or the huaweicloud_cce_autopilot_addon_templates data source before filling this in.
    Do not guess the values shape for an add-on you haven't checked.
  EOT
  type = map(object({
    addon_template_name = string
    version             = optional(string)
    name                = optional(string)
    alias               = optional(string)
    values              = map(string) # each value must already be a JSON-encoded string
  }))
  default = {}
}
