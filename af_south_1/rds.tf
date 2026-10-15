#rds — PostgreSQL for the IMTO test backend (see test_app/backend, which connects via
#Npgsql using DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD env vars). Private throughout:
#lives in its own dedicated subnet, reachable only from the CCE pod subnet on 5432.
#Credentials never appear in this repo in plaintext — generated here, then handed to CSMS
#(secrets.tf) so CCE pods pull them via the dew-provider add-on, never baked into an image
#or committed as a K8s Secret manifest.

resource "huaweicloud_networking_secgroup" "juliet_rds_sg" {
  name        = "juliet-cce-rds-sg"
  description = "RDS PostgreSQL — allow 5432 only from the CCE pod subnet"
}

resource "huaweicloud_networking_secgroup_rule" "juliet_rds_allow_pg_from_pods" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = module.juliet_eni_subnet.subnet_cidr # only the pod subnet — not the master or public subnets
  security_group_id = huaweicloud_networking_secgroup.juliet_rds_sg.id
}

# Auto-selects a small starter flavor for af-south-1 rather than hardcoding a flavor code,
# since flavor codes/availability are region-specific and easy to get wrong by guessing.
# Confirm this picked a sensible size before relying on it — bump vcpus/memory for anything
# beyond testing.
data "huaweicloud_rds_flavors" "pg" {
  db_type       = "PostgreSQL"
  db_version    = "14"
  instance_mode = "single"
  vcpus         = 2
  memory        = 4
}

# Same reasoning as the flavor lookup above — "ULTRAHIGH" was rejected outright
# ("Invalid storagetype") since not every storage type is available in every
# region/AZ. Picks the first type actually available ("normal") in af-south-1a
# instead of guessing one from Huawei's general (non-region-specific) docs.
data "huaweicloud_rds_storage_types" "pg" {
  db_type       = "PostgreSQL"
  db_version    = "14"
  instance_mode = "single"
}

resource "random_password" "rds_admin" {
  length           = 20
  override_special = "~!@#%^*-_=+?" # Huawei RDS's allowed special-character set — not the full ASCII punctuation set
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "imto_app_db" {
  length           = 24
  override_special = "~!@#%^*-_=+?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

module "juliet_rds_postgres" {
  source = "../modules/rds_postgres"

  instance_name     = "juliet-imto-test-pg"
  vpc_id            = module.juliet_vpc.vpc_id
  subnet_id         = module.juliet_db_subnet.subnet_id
  security_group_id = huaweicloud_networking_secgroup.juliet_rds_sg.id
  availability_zone = ["af-south-1a"] # single instance — add a second AZ + an .ha flavor for Primary/Standby later

  flavor     = try(data.huaweicloud_rds_flavors.pg.flavors[0].name, null) # errors clearly at plan time if nothing matched, rather than silently using a wrong flavor
  pg_version = "14"

  admin_password = random_password.rds_admin.result # only used for the default superuser — the app never uses this account

  volume_type = try(
    [for st in data.huaweicloud_rds_storage_types.pg.storage_types : st.name if try(st.az_status["af-south-1a"], "") == "normal"][0],
    null # errors clearly at apply time against the real API if nothing matched, rather than silently using a wrong type
  )
  volume_size = 40 # GB — starter size, resize once real data volume is known

  backup_keep_days  = 7
  backup_start_time = "02:00-03:00"

  accounts = {
    imto_app = {
      password    = random_password.imto_app_db.result
      description = "App account for the IMTO test backend" # plain words only - the old text with a comma and an em dash was rejected (DBS.301161)
    }
  }

  databases = {
    imto_test = {
      owner       = "imto_app"
      description = "IMTO test app database"
    }
  }

  tags = merge(local.common_tags, { ManagedBy = "Terraform" })
}

output "rds_private_ip" {
  description = "RDS instance's private IP — matches what gets pushed into CSMS as imto-db-host (see secrets.tf)."
  value       = module.juliet_rds_postgres.private_ip[0]
}