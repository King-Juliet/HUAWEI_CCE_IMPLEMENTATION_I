resource "huaweicloud_cce_autopilot_cluster" "prod_k8s" {
  region      = var.region       # Huawei Cloud region to create the cluster in. If left null, uses the provider's default region.
  name        = var.cluster_name # Cluster's actual name. 4-128 chars, lowercase letters/digits/hyphens only, can't end in a hyphen.
  alias       = var.alias        # Optional display name shown in the console. Defaults to the cluster name if not set.
  description = var.description  # Free-text note describing what this cluster is for — shows up in the console.

  flavor   = "cce.autopilot.cluster" # Fixed value — this is what tells Huawei "this is an Autopilot cluster." No other value is valid here.
  category = "Turbo"                 # Fixed value required for Autopilot clusters — refers to Huawei's high-performance networking mode.
  type     = "VirtualMachine"        # Master node architecture — VirtualMachine means standard x86 servers run the control plane.

  host_network {
    vpc    = var.vpc_id    # ID of the existing VPC where the cluster's master (control plane) node will live.
    subnet = var.subnet_id # ID of the existing subnet inside that VPC for the master node.
  }

  container_network {
    mode = "eni" # Networking mode for pods/containers. "eni" means each pod gets its own ENI (network interface) — required for Autopilot.
  }

  eni_network {
    dynamic "subnets" {             # Loops over every subnet ID you pass in, since a cluster can span multiple subnets.
      for_each = var.eni_subnet_ids # The list of subnet IDs to use for pod networking (control nodes + containers).
      content {
        subnet_id = subnets.value # Each individual subnet's IPv4 subnet ID — must be the "ipv4_subnet_id", not the plain subnet ID.
      }
    }
  }

  dynamic "service_network" { # Only creates this block at all if you actually provided a CIDR — otherwise Huawei uses its own default.
    for_each = var.service_network_cidr == null ? [] : [var.service_network_cidr]
    content {
      ipv4_cidr = service_network.value # The internal IP range Kubernetes uses for its own service-to-service communication (not your app traffic).
    }
  }

  dynamic "authentication" { # Only sent if explicitly set — the Autopilot API rejects the block outright ("does not support specifying Authentication values") when present at all, even with the "default" rbac value.
    for_each = var.authentication_mode == null ? [] : [var.authentication_mode]
    content {
      mode = authentication.value # How users/systems authenticate to the cluster's API — "rbac" (role-based access control) is the standard/default.
    }
  }

  eip_id                  = var.eip_id                  # Optional public IP to attach to the cluster's API server. Leave null to keep the cluster private (no public access).
  enable_snat             = var.enable_snat             # Whether cluster resources can reach the internet outbound via NAT Gateway (e.g. to call external APIs/partners).
  enable_swr_image_access = var.enable_swr_image_access # Whether the cluster pulls container images from SWR privately (through a VPC endpoint) instead of over the public internet.
  deletion_protection     = var.deletion_protection     # Safety switch — if true, this cluster cannot be deleted until protection is explicitly turned off first.

  dynamic "extend_param" { # Only adds this block if you provided an enterprise project ID — used for cost/governance grouping in larger orgs.
    for_each = var.enterprise_project_id == null ? [] : [var.enterprise_project_id]
    content {
      enterprise_project_id = extend_param.value # The ID of the enterprise project this cluster's costs/resources should be grouped under.
    }
  }

  tags = var.tags # Key-value labels attached to the cluster (e.g. environment=production) — useful for filtering/billing in the console.

  delete_efs         = var.delete_efs         # What to do with SFS Turbo (file storage) volumes when this cluster is deleted — keep, try, or force delete.
  delete_eni         = var.delete_eni         # What to do with the ENI network ports when the cluster is deleted.
  delete_net         = var.delete_net         # What to do with cluster-created network resources (e.g. load balancers) when the cluster is deleted.
  delete_obs         = var.delete_obs         # What to do with any OBS (object storage) volumes tied to this cluster when it's deleted.
  delete_sfs30       = var.delete_sfs30       # What to do with SFS 3.0 (a newer file storage type) volumes when the cluster is deleted.
  lts_reclaim_policy = var.lts_reclaim_policy # What to do with the cluster's log data (LTS) on deletion — delete the whole log group, just the main log stream, or keep everything.

  timeouts {
    create = "30m" # How long Terraform will wait for cluster creation to finish before giving up and erroring out.
    delete = "30m" # How long Terraform will wait for cluster deletion to finish before giving up and erroring out.
  }

  lifecycle {
    ignore_changes = [
      enable_snat, delete_efs, delete_obs, # Tells Terraform to stop trying to "correct" these three fields after creation — Huawei's API doesn't return their real value on import, so Terraform can't reliably track drift on them.
      tags,                                # Huawei adds a CCE-Cluster-ID tag itself after creation; without this Terraform tries to remove it on every plan.
    ]
  }
}