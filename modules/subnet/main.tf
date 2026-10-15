resource "huaweicloud_vpc_subnet" "juliet_subnet" {
  name              = var.subnet_name       #"juliet-subnet"
  cidr              = var.subnet_cidr       #"10.0.1.0/24"
  gateway_ip        = var.subnet_gateway_ip #"10.0.1.1"
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone #"af-south-1a"

  tags = {
    Owner       = var.subnet_owner
    Project     = var.subnet_project
    Environment = var.subnet_environment
    ManagedBy   = var.subnet_managed_by
  }

}