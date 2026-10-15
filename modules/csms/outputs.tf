output "secret_names" {
  description = "Map of tracking name -> the actual CSMS secret name — use these values as `objectName` in a CCE SecretProviderClass."
  value       = { for k, v in huaweicloud_csms_secret.this : k => v.name }
}

output "secret_ids" {
  description = "Map of tracking name -> CSMS secret resource ID."
  value       = { for k, v in huaweicloud_csms_secret.this : k => v.secret_id }
}
