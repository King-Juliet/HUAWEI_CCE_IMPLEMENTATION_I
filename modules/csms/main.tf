resource "huaweicloud_csms_secret" "this" {
  # nonsensitive() here only strips the taint for iteration purposes — the map KEYS (tracking
  # names like "db_host") aren't secret, only the secret_text VALUES are, and those stay
  # protected via the explicit sensitive() wrap below. Terraform disallows for_each over any
  # sensitive-tainted value outright (map keys become resource instance addresses, visible in
  # state/plan output), regardless of this variable's own `sensitive = true` — the taint here
  # actually comes from the root module's random_password.*.result inputs.
  for_each = nonsensitive(var.secrets) # one CSMS secret per entry — CCE's SecretProviderClass pulls each by its `name` below

  region      = var.region
  name        = coalesce(each.value.name, each.key)
  secret_text = sensitive(each.value.secret_text)
  description = each.value.description
  kms_key_id  = each.value.kms_key_id

  secret_type           = "COMMON" # only supported value currently
  enterprise_project_id = var.enterprise_project_id
  tags                  = var.tags
}
