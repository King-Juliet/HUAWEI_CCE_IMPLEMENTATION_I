#cce — CCE Autopilot cluster, private throughout: the master node lives in
#juliet-cce-subnet and pods (ENI mode) live in juliet-cce-eni-subnet (see vpc.tf). No EIP
#is bound to the cluster's API server (eip_id = null) — the only public entry point into
#this stack is the ELB defined in elb.tf, which fronts Envoy Gateway running inside CCE.
#
#Traffic flow (inbound):  user -> ELB (elb.tf, public EIP) -> Envoy Gateway Service in CCE
#                          (attached to that ELB via its kubernetes.io/elb.id annotation)
#                          -> application pods
#Traffic flow (outbound):  application pods -> NAT Gateway below (SNAT) -> internet
#                          -> third-party systems

module "juliet_cce_autopilot" {
  source = "../modules/cce_autopilot"

  cluster_name = "juliet-cce-autopilot"
  description  = "Production CCE Autopilot cluster for juliet workloads, fronted by Envoy Gateway via the public ELB"

  vpc_id    = module.juliet_vpc.vpc_id
  subnet_id = module.juliet_subnet.subnet_id # master/control-plane — private subnet

  eni_subnet_ids = [
    module.juliet_eni_subnet.subnet_ipv4_subnet_id, # pod networking — dedicated private subnet, ipv4_subnet_id (not plain id)
  ]

  eip_id = var.cluster_public_access ? huaweicloud_vpc_eip.api_temp[0].id : null # private by default; the CD pipeline binds a temporary EIP only during the one-time ARC install (see cluster_access.tf)

  enable_snat             = true  # pods reach third-party systems outbound via the NAT Gateway below
  enable_swr_image_access = true  # pull images from SWR over a private VPC endpoint rather than the public internet
  deletion_protection     = false # TESTING: matches the cluster's actual current state (Huawei didn't persist true from create). Flip back to true once you're done testing destroy/apply cycles — see note below.

  tags = merge(local.common_tags, { ManagedBy = "Terraform" })

  # Make sure our own NAT Gateway + SNAT rule exist before the cluster starts relying on
  # enable_snat — otherwise Huawei may try to auto-provision its own NAT gateway/EIP first.
  depends_on = [
    huaweicloud_nat_gateway.juliet_nat_gw,
    huaweicloud_nat_snat_rule.juliet_nat_snat,
  ]
}

#nat — outbound-only (SNAT) internet access for pods in the ENI subnet, so backend apps
#deployed to CCE can call third-party systems. No DNAT rules are created: inbound traffic
#comes only through the ELB -> Envoy Gateway path above, never straight through NAT.

resource "huaweicloud_vpc_eip" "nat_eip" {
  name        = "juliet-cce-nat-eip"
  description = "EIP for juliet-cce-nat-gw (pod egress to third-party systems)"

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    share_type  = "PER"
    name        = "juliet-cce-nat-bandwidth"
    size        = 20 # Mbit/s — starter size, raise once real egress volume is known.
    charge_mode = "traffic"
  }

  tags = merge(local.common_tags, { ManagedBy = "Terraform" })
}

resource "huaweicloud_nat_gateway" "juliet_nat_gw" {
  name        = "juliet-cce-nat-gw"
  description = "SNAT egress for juliet CCE pods to reach third-party systems"
  vpc_id      = module.juliet_vpc.vpc_id
  subnet_id   = module.juliet_eni_subnet.subnet_id # downstream interface lives alongside the pods it serves
  spec        = "1"                                # smallest tier (~10,000 SNAT connections) — resize once real load is known.

  tags = merge(local.common_tags, { ManagedBy = "Terraform" })
}

resource "huaweicloud_nat_snat_rule" "juliet_nat_snat" {
  nat_gateway_id = huaweicloud_nat_gateway.juliet_nat_gw.id
  subnet_id      = module.juliet_eni_subnet.subnet_id # every pod IP in this subnet gets SNAT'd through nat_eip
  floating_ip_id = huaweicloud_vpc_eip.nat_eip.id
  description    = "SNAT for CCE pod subnet to internet"
}


# ADD ONS
# ---------------------------------------------------------------------------
# CoreDNS is deliberately NOT installed here — confirmed against Huawei's own
# docs that it's a mandatory system add-on auto-installed at cluster creation
# for every Autopilot cluster ("This add-on is installed by default during
# cluster creation"). The earlier attempt to install it via
# huaweicloud_cce_autopilot_addon failed with "conflict in the request" for
# exactly that reason — it already exists the moment the cluster comes up, so
# there was never anything to wait on before installing the add-ons below
# either (the original time_sleep + separate dns module existed only to
# sequence around a CoreDNS install that shouldn't have been attempted).
#
# FIXED (kept from an earlier pass): source points at this repo's actual
# module directory (modules/cce_addons, not the nonexistent
# "../cce-autopilot-addons"), and cluster_id references this file's real
# cluster module (module.juliet_cce_autopilot, not the nonexistent
# "module.cce_autopilot_prod").
#
# Envoy Gateway is deliberately NOT in this list — confirmed (against
# Huawei's own CCE Autopilot add-on catalog docs and their Envoy Gateway
# best-practice guide) that it is NOT a native CCE add-on at all; there is
# no real "envoy-gateway" addon_template_name to install here. It installs
# as a normal Kubernetes workload via Helm, after this apply finishes:
#
#   helm upgrade -i eg oci://docker.io/envoyproxy/gateway-helm \
#     --version <version> \
#     --namespace envoy-gateway-system --create-namespace
#
# then Envoy Gateway's own Service gets bound to the pre-created public ELB
# (module.juliet_elb.loadbalancer_id, see elb.tf's `elb_id` output) via the
# EnvoyProxy resource's spec.provider.kubernetes.envoyService.annotations
# field (kubernetes.io/elb.id = <that id>) — see k8s/envoy-gatewayclass.yaml.
# ---------------------------------------------------------------------------
module "cce_addons_prod" {
  source = "../modules/cce_addons"

  cluster_id = module.juliet_cce_autopilot.cluster_id

  addons = {
    logging = {
      addon_template_name = "log-agent"
      # version omitted — same reasoning as coredns above: "1.4.3" was never confirmed
      # against the real template catalog, so don't hardcode it blind either.
      values = {
        basic  = jsonencode({})
        flavor = jsonencode({})
        custom = jsonencode({})
      }
    }

    secrets = {
      addon_template_name = "dew-provider"
      values = {
        basic = jsonencode({}) # confirmed against Huawei's API reference (cce_02_0418.html) — "does not need to be specified"
        # custom.rotation_poll_interval is mandatory (its absence caused "rotation_poll_interval
        # is empty") — confirmed format is a duration string like "2m", not a bare number, and
        # the valid range is 1m-1440m per the same API reference doc.
        custom = jsonencode({
          rotation_poll_interval = "2m"
        })
      }
    }
  }

  # No explicit depends_on needed — cluster_id above already creates an implicit
  # dependency on module.juliet_cce_autopilot, and CoreDNS (which these add-ons don't
  # actually need to wait on themselves) is already handled by Huawei at cluster creation.
}