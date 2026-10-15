# Temporary public access to the kube-apiserver — used ONLY by the CD pipeline's one-time
# ARC bootstrap job, which sets cluster_public_access=true, installs ARC, then closes access in
# two applies: first keep_temp_eip=true (EIP detached from the cluster but not yet deleted), then
# the default (both false) so the now-detached EIP is destroyed. Doing it in two steps stops
# Terraform trying to delete the EIP while it is still attached. Normal state: private.

variable "cluster_public_access" {
  description = "Bind a temporary EIP to the kube-apiserver. Set to true only by the CD bootstrap job."
  type        = bool
  default     = false
}

variable "keep_temp_eip" {
  description = "Keep the temporary EIP in existence while it is detached from the cluster. Only used by the CD pipeline's two-step close."
  type        = bool
  default     = false
}

resource "huaweicloud_vpc_eip" "api_temp" {
  count = (var.cluster_public_access || var.keep_temp_eip) ? 1 : 0

  name = "juliet-cce-api-temp-eip"

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    share_type  = "PER"
    name        = "juliet-cce-api-temp-bandwidth"
    size        = 5
    charge_mode = "traffic"
  }

  tags = merge(local.common_tags, { ManagedBy = "Terraform", Purpose = "temporary-arc-bootstrap" })
}

# Short-lived (1 day) client certificate kubeconfig. Only exists while access is open;
# removed from state again when the closing apply runs.
data "huaweicloud_cce_autopilot_cluster_certificate" "bootstrap" {
  count = var.cluster_public_access ? 1 : 0

  cluster_id = module.juliet_cce_autopilot.cluster_id
  duration   = 1

  depends_on = [module.juliet_cce_autopilot]
}

output "bootstrap_kubeconfig" {
  description = "Temporary kubeconfig for the ARC bootstrap job. Empty unless cluster_public_access=true."
  value       = try(data.huaweicloud_cce_autopilot_cluster_certificate.bootstrap[0].kube_config_raw, "")
  sensitive   = true
}