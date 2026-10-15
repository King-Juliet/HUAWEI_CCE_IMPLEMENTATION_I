#elb — public-facing dedicated ELB, sitting in the public subnet. This is the entry point
#users hit; traffic flow is: user -> this ELB (public EIP) -> Envoy Gateway Service inside
#CCE (private ENI subnet) -> application pods. Terraform only stands up the LB shell here —
#see modules/elb/main.tf for why listeners/pools are deliberately left for CCE's
#cloud-controller-manager to attach once Envoy Gateway's Service references this LB's id.

module "juliet_elb" {
  source = "../modules/elb"

  elb_name    = "juliet-cce-public-elb"
  description = "Public entry point for the juliet CCE cluster, fronting Envoy Gateway"

  vpc_id            = module.juliet_vpc.vpc_id
  subnet_id         = module.juliet_public_subnet.subnet_ipv4_subnet_id
  availability_zone = ["af-south-1a"]

  create_eip                = true
  eip_name                  = "juliet-cce-elb-eip"
  eip_bandwidth_name        = "juliet-cce-elb-bandwidth"
  eip_bandwidth_size        = 20 # Mbit/s — starter size, raise once real traffic is known.
  eip_bandwidth_charge_mode = "traffic"

  deletion_protection_enable = false # Prod — avoid accidental deletion of the public entry point.

  tags = merge(local.common_tags, { ManagedBy = "Terraform" })
}

output "elb_public_ip" {
  description = "Public IP users will hit to reach the frontend app via Envoy Gateway."
  value       = module.juliet_elb.public_ip
}

output "elb_id" {
  description = "ELB id — put this in the Envoy Gateway Service's kubernetes.io/elb.id annotation."
  value       = module.juliet_elb.loadbalancer_id
}
