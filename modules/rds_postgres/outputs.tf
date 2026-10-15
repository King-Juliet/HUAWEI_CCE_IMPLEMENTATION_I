output "instance_id" {
  description = "ID of the RDS instance."
  value       = huaweicloud_rds_instance.this.id
}

output "private_ip" {
  description = "Private IP address(es) of the instance, inside the VPC — this is what CCE pods connect to as DB_HOST."
  value       = huaweicloud_rds_instance.this.private_ips
}

output "port" {
  description = "PostgreSQL port. Huawei RDS PostgreSQL always listens on 5432."
  value       = 5432
}

output "status" {
  description = "Current instance status."
  value       = huaweicloud_rds_instance.this.status
}

output "account_ids" {
  description = "Map of account name -> its resource ID."
  value       = { for k, v in huaweicloud_rds_pg_account.this : k => v.id }
}

output "database_ids" {
  description = "Map of database name -> its resource ID."
  value       = { for k, v in huaweicloud_rds_pg_database.this : k => v.id }
}
