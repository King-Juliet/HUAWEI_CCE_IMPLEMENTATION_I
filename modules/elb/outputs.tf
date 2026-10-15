output "loadbalancer_id" {
  description = "ID of the ELB load balancer. Reference this in the Envoy Gateway Service's kubernetes.io/elb.id annotation so CCE attaches to this pre-existing LB instead of creating a new one."
  value       = huaweicloud_elb_loadbalancer.this.id
}

output "loadbalancer_name" {
  description = "Name of the load balancer."
  value       = huaweicloud_elb_loadbalancer.this.name
}

output "private_ip" {
  description = "Private (VIP) IPv4 address of the load balancer inside the VPC."
  value       = huaweicloud_elb_loadbalancer.this.ipv4_address
}

output "public_ip" {
  description = "Public IPv4 address (EIP) bound to the load balancer — this is what end users hit."
  value       = huaweicloud_elb_loadbalancer.this.ipv4_eip
}

output "eip_id" {
  description = "ID of the EIP bound to the load balancer (null if create_eip = false and no existing_eip_id was resolved)."
  value       = var.create_eip ? huaweicloud_vpc_eip.this[0].id : var.existing_eip_id
}

