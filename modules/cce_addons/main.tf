resource "huaweicloud_cce_autopilot_addon" "k8s_addons" {
  for_each = var.addons # One resource per entry in the addons map — lets you install several add-ons from one module call.

  region              = var.region                     # Region to install into — usually left null to match the provider default.
  cluster_id          = var.cluster_id                 # Which cluster this add-on attaches to.
  addon_template_name = each.value.addon_template_name # The specific add-on being installed, e.g. "log-agent" or "coredns".
  version             = each.value.version             # Which version of that add-on to install — optional, Huawei picks a default if omitted.
  name                = each.value.name                # Optional custom name for this add-on instance.
  alias               = each.value.alias               # Optional display alias shown in the console.
  values              = each.value.values              # Add-on-specific config, passed as a map of JSON-encoded strings — shape varies per add-on.

  lifecycle {
    ignore_changes = [
      values, # Huawei's API doesn't return "values" on import, so Terraform can't reliably track drift on it — same reasoning as the cluster's enable_snat/delete_efs/delete_obs earlier.
    ]
  }
}