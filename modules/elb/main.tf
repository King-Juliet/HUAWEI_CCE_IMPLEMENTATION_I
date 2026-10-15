data "huaweicloud_elb_flavors" "l4" { # Only queried when no explicit l4_flavor_id was passed in.
  count = var.l4_flavor_id == null ? 1 : 0
  type  = var.l4_flavor_type
}

data "huaweicloud_elb_flavors" "l7" { # Only queried when L7 capability was asked for but no explicit id was passed in.
  count = var.l7_flavor_id == null && var.create_l7_flavor_lookup ? 1 : 0
  type  = var.l7_flavor_type
}

resource "huaweicloud_vpc_eip" "this" { # Public IP bound to the load balancer — this, not subnet routing, is what makes the LB internet-reachable.
  count       = var.create_eip ? 1 : 0
  region      = var.region
  name        = coalesce(var.eip_name, "${var.elb_name}-eip")
  description = "EIP for ELB ${var.elb_name}"

  publicip {
    type = var.eip_type
  }

  bandwidth {
    share_type  = "PER"
    name        = coalesce(var.eip_bandwidth_name, "${var.elb_name}-bw")
    size        = var.eip_bandwidth_size
    charge_mode = var.eip_bandwidth_charge_mode
  }

  tags = var.tags
}

resource "huaweicloud_elb_loadbalancer" "this" {
  region      = var.region
  name        = var.elb_name
  description = var.description

  vpc_id            = var.vpc_id
  ipv4_subnet_id    = var.subnet_id # Must be the subnet's ipv4_subnet_id, not its plain subnet_id.
  availability_zone = var.availability_zone
  cross_vpc_backend = var.cross_vpc_backend

  l4_flavor_id = coalesce(var.l4_flavor_id, try(data.huaweicloud_elb_flavors.l4[0].flavors[0].id, null))
  l7_flavor_id = var.l7_flavor_id != null ? var.l7_flavor_id : (
    var.create_l7_flavor_lookup ? try(data.huaweicloud_elb_flavors.l7[0].flavors[0].id, null) : null
  )

  # Binds this LB to a public EIP (create_eip = true) or an existing one you already own.
  ipv4_eip_id = var.create_eip ? huaweicloud_vpc_eip.this[0].id : var.existing_eip_id

  protection_status          = var.protection_status
  deletion_protection_enable = var.deletion_protection_enable
  enterprise_project_id      = var.enterprise_project_id

  tags = var.tags

  # Listeners/pools/members are intentionally NOT created here. In the intended setup,
  # Envoy Gateway's Kubernetes Service (type LoadBalancer) is annotated with
  # kubernetes.io/elb.id = <this LB's id> so CCE's cloud-controller-manager attaches the
  # listener/pool/backend wiring to THIS pre-existing ELB automatically. Managing those
  # sub-resources here as well would fight with what CCE manages dynamically.
}
