output "subnet_id" {
  description = "ID of the subnet"
  value       = huaweicloud_vpc_subnet.juliet_subnet.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = huaweicloud_vpc_subnet.juliet_subnet.name
}

output "subnet_cidr" {
  description = "CIDR block of the subnet"
  value       = huaweicloud_vpc_subnet.juliet_subnet.cidr
}

output "subnet_availability_zone" {
  description = "Availability zone of the subnet"
  value       = huaweicloud_vpc_subnet.juliet_subnet.availability_zone
}

output "subnet_ipv4_subnet_id" {
  description = "IPv4 subnet ID of the subnet — distinct from subnet_id. Required (not the plain subnet_id) wherever CCE Turbo/ENI networking or a dedicated ELB asks for a subnet, e.g. cce_autopilot's eni_subnet_ids and the elb module's subnet_id."
  value       = huaweicloud_vpc_subnet.juliet_subnet.ipv4_subnet_id
}