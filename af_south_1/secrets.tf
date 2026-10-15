#secrets — pushes the RDS connection details into CSMS under the exact names
#k8s/backend-secretproviderclass.yaml's SecretProviderClass expects as `objectName`
#(imto-db-host/port/name/user/password), so the dew-provider add-on (cce.tf) can sync
#them into the backend pod without any credential ever being written into this repo
#or a K8s Secret manifest by hand.

module "juliet_csms_secrets" {
  source = "../modules/csms"

  secrets = {
    db_host = {
      name        = "imto-db-host"
      secret_text = module.juliet_rds_postgres.private_ip[0]
      description = "IMTO test backend — RDS private IP"
    }
    db_port = {
      name        = "imto-db-port"
      secret_text = tostring(module.juliet_rds_postgres.port)
      description = "IMTO test backend — RDS port"
    }
    db_name = {
      name        = "imto-db-name"
      secret_text = "imto_test" # must match rds.tf's databases.imto_test key
      description = "IMTO test backend — database name"
    }
    db_user = {
      name        = "imto-db-user"
      secret_text = "imto_app" # must match rds.tf's accounts.imto_app key
      description = "IMTO test backend — database app account"
    }
    db_password = {
      name        = "imto-db-password"
      secret_text = random_password.imto_app_db.result # generated in rds.tf, never written down elsewhere
      description = "IMTO test backend — database app account password"
    }
  }

  tags = merge(local.common_tags, { ManagedBy = "Terraform" })
}

# BEST-EVIDENCED DIAGNOSIS, NOT DOC-CONFIRMED: the dew-provider pod (running on the ENI/pod
# subnet) times out reaching kms.<region>.myhuaweicloud.com, which resolves internally to a
# 100.125.0.0/16 address — Huawei's private-service address range. The cluster's own
# enable_swr_image_access = true (cce.tf) already auto-creates equivalent private VPC
# Endpoints for SWR/OBS specifically (visible in the console as "SWR Endpoint: Configured" /
# "OBS Endpoint: Configured") — but nothing auto-creates one for KMS/CSMS, which dew-provider
# needs to actually fetch secrets. This endpoint is the parallel fix for that gap.
#
# VERIFY BEFORE RELYING ON THIS: confirm "kms" actually appears in Console -> VPC -> VPC
# Endpoint -> VPC Endpoint Services (or via the data source below) for af-south-1 before
# assuming this resolves it — if the backend pods still time out after this applies, the
# root cause is something else and this endpoint should be removed (it has a small hourly
# cost while it exists).
data "huaweicloud_vpcep_public_services" "kms" {
  service_name = "kms"
}

resource "huaweicloud_vpcep_endpoint" "kms" {
  service_id = data.huaweicloud_vpcep_public_services.kms.services[0].id
  vpc_id     = module.juliet_vpc.vpc_id
  network_id = module.juliet_eni_subnet.subnet_id # the pod subnet — where dew-provider actually needs the route from
  enable_dns = true                               # so kms.af-south-1.myhuaweicloud.com resolves to this endpoint's private address for pods in this VPC
}
