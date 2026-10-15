#vpc

module "juliet_vpc" {
  source          = "../modules/vpc"
  vpc_name        = "juliet-cce-vpc"
  vpc_cidr        = "10.0.0.0/16"
  vpc_owner       = local.common_tags["Owner"]
  vpc_project     = local.common_tags["Project"]
  vpc_environment = local.common_tags["Environment"]

}

#subnet — private, hosts the CCE Autopilot master (control plane) node
module "juliet_subnet" {
  source             = "../modules/subnet"
  subnet_name        = "juliet-cce-subnet"
  subnet_cidr        = "10.0.1.0/24"
  subnet_gateway_ip  = "10.0.1.1"
  vpc_id             = module.juliet_vpc.vpc_id
  availability_zone  = "af-south-1a"
  subnet_owner       = local.common_tags["Owner"]
  subnet_project     = local.common_tags["Project"]
  subnet_environment = local.common_tags["Environment"]

}

#subnet — private, dedicated to CCE Turbo/ENI pod networking. Kept separate from the
#master subnet above because in ENI mode every pod consumes a real VPC IP; a /20 here
#leaves headroom (~4k IPs) so Envoy Gateway + application pods don't exhaust a shared /24.
module "juliet_eni_subnet" {
  source             = "../modules/subnet"
  subnet_name        = "juliet-cce-eni-subnet"
  subnet_cidr        = "10.0.16.0/20"
  subnet_gateway_ip  = "10.0.16.1"
  vpc_id             = module.juliet_vpc.vpc_id
  availability_zone  = "af-south-1a"
  subnet_owner       = local.common_tags["Owner"]
  subnet_project     = local.common_tags["Project"]
  subnet_environment = local.common_tags["Environment"]

}

#subnet — for the public-facing ELB in front of Envoy Gateway. Note: in Huawei VPC every
#subnet is "private" by default (no internet gateway concept like AWS) — what actually
#makes the ELB internet-reachable is binding an EIP directly to it (see modules/elb).
#This subnet just physically segregates the LB's downstream port from CCE's own subnets.
module "juliet_public_subnet" {
  source             = "../modules/subnet"
  subnet_name        = "juliet-cce-public-subnet"
  subnet_cidr        = "10.0.32.0/24"
  subnet_gateway_ip  = "10.0.32.1"
  vpc_id             = module.juliet_vpc.vpc_id
  availability_zone  = "af-south-1a"
  subnet_owner       = local.common_tags["Owner"]
  subnet_project     = local.common_tags["Project"]
  subnet_environment = local.common_tags["Environment"]

}

#subnet — private, dedicated to the RDS PostgreSQL instance (see rds.tf). Kept separate
#from both the master and pod subnets so database access can be locked down by security
#group to only the pod subnet's CIDR, rather than sharing a broadcast domain with anything else.
module "juliet_db_subnet" {
  source             = "../modules/subnet"
  subnet_name        = "juliet-cce-db-subnet"
  subnet_cidr        = "10.0.33.0/24"
  subnet_gateway_ip  = "10.0.33.1"
  vpc_id             = module.juliet_vpc.vpc_id
  availability_zone  = "af-south-1a"
  subnet_owner       = local.common_tags["Owner"]
  subnet_project     = local.common_tags["Project"]
  subnet_environment = local.common_tags["Environment"]

}
