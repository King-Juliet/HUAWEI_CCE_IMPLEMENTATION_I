variable "region" {
  description = "Huawei Cloud region to create the load balancer in. If omitted, the provider-level region is used."
  type        = string
  default     = null
}

variable "elb_name" {
  description = "Name of the dedicated (v3) ELB load balancer."
  type        = string
}

variable "description" {
  description = "Free-text description of the load balancer."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the existing VPC to create the load balancer in."
  type        = string
}

variable "subnet_id" {
  description = "IPv4 subnet ID (not the plain subnet ID — use the subnet module's subnet_ipv4_subnet_id output) of the subnet the load balancer's own downstream port lives in."
  type        = string
}

variable "availability_zone" {
  description = "List of AZ names to spread the dedicated load balancer across, e.g. [\"af-south-1a\"]. At least one is required."
  type        = list(string)
}

variable "l4_flavor_id" {
  description = "L4 (TCP/UDP) flavor ID for the dedicated LB. Leave null to auto-select the first flavor matching l4_flavor_type/l4_flavor_filters via a data source lookup — confirm the picked flavor is the right size for Prod before first apply, then consider pinning it explicitly."
  type        = string
  default     = null
}

variable "l4_flavor_type" {
  description = "Flavor 'type' filter used for the l4_flavor_id lookup when l4_flavor_id is null. One of L4, L4_elastic_max."
  type        = string
  default     = "L4"
}

variable "l7_flavor_id" {
  description = "L7 (HTTP/HTTPS) flavor ID for the dedicated LB. Leave null to skip provisioning L7 capability, or set create_l7_flavor_lookup = true to auto-select one. Only needed if the ELB itself will do HTTP-level routing/TLS termination in front of Envoy Gateway — often left null when Envoy Gateway handles all L7 concerns and the ELB just does L4 passthrough."
  type        = string
  default     = null
}

variable "create_l7_flavor_lookup" {
  description = "Whether to auto-select an l7_flavor_id via data source lookup when l7_flavor_id is null."
  type        = bool
  default     = false
}

variable "l7_flavor_type" {
  description = "Flavor 'type' filter used for the l7_flavor_id lookup. One of L7, L7_elastic_max."
  type        = string
  default     = "L7"
}

variable "create_eip" {
  description = "Whether this module provisions a new EIP and binds it to the load balancer (making it internet-facing). Set false if you'll bind an existing EIP via existing_eip_id instead, or keep the LB private."
  type        = bool
  default     = true
}

variable "existing_eip_id" {
  description = "ID of an existing EIP to bind instead of creating a new one. Only used when create_eip = false."
  type        = string
  default     = null
}

variable "eip_name" {
  description = "Name for the EIP created for this load balancer (only used when create_eip = true)."
  type        = string
  default     = null
}

variable "eip_type" {
  description = "EIP line type. 5_bgp (dynamic BGP) or 5_sbgp (static BGP)."
  type        = string
  default     = "5_bgp"
}

variable "eip_bandwidth_name" {
  description = "Name of the dedicated (PER) bandwidth for the EIP."
  type        = string
  default     = null
}

variable "eip_bandwidth_size" {
  description = "Dedicated bandwidth size in Mbit/s for the EIP (1-300)."
  type        = number
  default     = 20
}

variable "eip_bandwidth_charge_mode" {
  description = "Billing mode for the EIP's dedicated bandwidth: traffic or bandwidth."
  type        = string
  default     = "traffic"
}

variable "cross_vpc_backend" {
  description = "Whether to enable IP-as-backend so the LB can target pod/ENI IPs directly (needed for Envoy Gateway pods registered by IP rather than by ECS instance)."
  type        = bool
  default     = true
}

variable "protection_status" {
  description = "Modification protection status: nonProtection or consoleProtection."
  type        = string
  default     = "nonProtection"
}

variable "deletion_protection_enable" {
  description = "Whether to enable deletion protection on the load balancer. Recommended true for Production."
  type        = bool
  default     = false
}

variable "enterprise_project_id" {
  description = "Optional enterprise project ID to associate the load balancer with."
  type        = string
  default     = null
}

variable "tags" {
  description = "Key-value tags applied to the load balancer and the EIP it creates."
  type        = map(string)
  default     = {}
}
