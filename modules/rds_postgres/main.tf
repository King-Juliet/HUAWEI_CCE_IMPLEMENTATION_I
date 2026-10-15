resource "huaweicloud_rds_instance" "this" {
  region            = var.region
  name              = var.instance_name
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  availability_zone = var.availability_zone # 1 entry = single instance, 2 = Primary/Standby (needs an .ha flavor)

  flavor = var.flavor

  db {
    type     = "PostgreSQL"
    version  = var.pg_version
    password = var.admin_password # default admin/superuser account — app workloads use var.accounts below instead
  }

  volume {
    type = var.volume_type
    size = var.volume_size
  }

  backup_strategy {
    keep_days  = var.backup_keep_days
    start_time = var.backup_start_time
  }

  # Only relevant/sent meaningfully when availability_zone has 2 entries — harmless no-op otherwise.
  ha_replication_mode = length(var.availability_zone) > 1 ? var.ha_replication_mode : null

  dynamic "parameters" {
    for_each = var.parameters
    content {
      name  = parameters.value.name
      value = parameters.value.value
    }
  }

  charging_mode         = var.charging_mode
  enterprise_project_id = var.enterprise_project_id
  tags                  = var.tags

  lifecycle {
    ignore_changes = [
      db[0].password, # Huawei's API doesn't return the password on refresh — avoid perpetual diffs once it's set.
    ]
  }
}

resource "huaweicloud_rds_pg_account" "this" {
  # See modules/csms/main.tf's comment on nonsensitive() here — same reasoning: only the
  # password VALUES are secret, not the map keys, and the password stays protected via the
  # explicit sensitive() wrap below.
  for_each = nonsensitive(var.accounts) # one non-admin role per entry, e.g. the app's own DB user

  instance_id = huaweicloud_rds_instance.this.id
  name        = coalesce(each.value.name, each.key)
  password    = sensitive(each.value.password)
  description = each.value.description
}

resource "huaweicloud_rds_pg_database" "this" {
  for_each = var.databases # one application database per entry, owned by one of the accounts above

  instance_id = huaweicloud_rds_instance.this.id
  name        = coalesce(each.value.name, each.key)
  owner       = each.value.owner
  description = each.value.description

  depends_on = [
    huaweicloud_rds_pg_account.this, # the owning account must exist before a database can be assigned to it
  ]
}
