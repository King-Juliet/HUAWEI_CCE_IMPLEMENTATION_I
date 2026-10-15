variable "region" {
  description = "Huawei Cloud region to create the cluster in. If omitted, the provider-level region is used."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Cluster name. 4-128 chars, starts with a lowercase letter, no trailing hyphen. Lowercase letters, digits, hyphens only."
  type        = string
}

variable "alias" {
  description = "Optional display alias for the cluster. Defaults to cluster_name if not set."
  type        = string
  default     = null
}

variable "description" {
  description = "Free-text description of the cluster."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the existing VPC to host the cluster's master node."
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing subnet to host the cluster's master node."
  type        = string
}

variable "eni_subnet_ids" {
  description = "List of IPv4 subnet IDs used for the ENI container network (control nodes and pods). Provide the ipv4_subnet_id of each subnet, not the plain subnet ID."
  type        = list(string)
}

variable "eip_id" {
  description = "Optional existing EIP ID to bind to the cluster (public API server access). Leave null to keep the cluster private."
  type        = string
  default     = null
}

variable "enable_snat" {
  description = "Whether the cluster can reach the internet via NAT gateway. If true and no NAT gateway exists in the VPC, Huawei auto-creates one bound to a new EIP — confirm this is intended before enabling in Prod."
  type        = bool
  default     = false
}

variable "enable_swr_image_access" {
  description = "Whether the cluster is wired up with private VPC endpoints to pull images from SWR (and the OBS it depends on) instead of over the public internet. Recommended true for Production."
  type        = bool
  default     = true
}

variable "service_network_cidr" {
  description = "IPv4 CIDR for the internal Kubernetes service network. Defaults to Huawei's own default (10.247.0.0/16) if left null — verify this doesn't collide with the VPC CIDR(s) in use."
  type        = string
  default     = null
}

variable "authentication_mode" {
  description = "Cluster authentication mode. Leave null (default) to omit the field entirely — Huawei's Autopilot API rejects the authentication block outright if it's present at all, even set to the 'default' rbac value."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the cluster. Recommended true for Production, false for Dev."
  type        = bool
  default     = false
}

variable "enterprise_project_id" {
  description = "Optional enterprise project ID to associate the cluster with, for cost/governance grouping."
  type        = string
  default     = null
}

variable "tags" {
  description = "Key-value tags applied to the cluster."
  type        = map(string)
  default     = {}
}

variable "delete_efs" {
  description = "Whether to delete the SFS Turbo volume on cluster deletion."
  type        = string
  default     = "skip"
}

variable "delete_eni" {
  description = "Whether to delete the ENI port on cluster deletion."
  type        = string
  default     = "block"
}

variable "delete_net" {
  description = "Whether to delete cluster-created network resources (e.g. load balancers) on cluster deletion."
  type        = string
  default     = "block"
}

variable "delete_obs" {
  description = "Whether to delete the OBS volume on cluster deletion."
  type        = string
  default     = "skip"
}

variable "delete_sfs30" {
  description = "Whether to delete the SFS 3.0 volume on cluster deletion."
  type        = string
  default     = "skip"
}

variable "lts_reclaim_policy" {
  description = "What to do with LTS log resources on cluster deletion: Delete_Log_Group, Delete_Master_Log_Stream, or Retain."
  type        = string
  default     = "Delete_Master_Log_Stream"
}