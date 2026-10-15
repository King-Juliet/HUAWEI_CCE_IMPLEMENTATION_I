resource "huaweicloud_vpc" "juliet_vpc" {
  name = var.vpc_name #"juliet-vpc"
  cidr = "10.0.0.0/16"

  tags = {
    Owner       = var.vpc_owner
    Project     = var.vpc_project
    Environment = var.vpc_environment
    ManagedBy   = var.vpc_managed_by
  }
}
