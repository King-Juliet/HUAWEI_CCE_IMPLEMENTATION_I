output "addon_ids" {
  description = "Map of add-on name -> its resource ID, for reference or dependency chaining."
  value       = { for k, v in huaweicloud_cce_autopilot_addon.k8s_addons : k => v.id }
}

output "addon_statuses" {
  description = "Map of add-on name -> its current install status, useful for a quick health check after apply."
  value       = { for k, v in huaweicloud_cce_autopilot_addon.k8s_addons : k => v.status }
}