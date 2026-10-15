resource "huaweicloud_swr_organization" "this" {
  region = var.region
  name   = var.organization_name # globally unique — Huawei rejects names already taken by any tenant.
}

resource "huaweicloud_swr_repository" "this" {
  for_each = var.repositories # one repository per entry in the map, all inside the single organization above.

  region       = var.region
  organization = huaweicloud_swr_organization.this.name
  name         = coalesce(each.value.name, each.key)
  is_public    = each.value.is_public
  description  = each.value.description
  category     = each.value.category
}
