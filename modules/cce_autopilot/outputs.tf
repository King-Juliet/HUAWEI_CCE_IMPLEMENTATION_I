output "cluster_id" {
  description = "ID of the created CCE Autopilot cluster."
  value       = huaweicloud_cce_autopilot_cluster.prod_k8s.id
}

output "status_phase" {
  description = "Current lifecycle phase of the cluster (e.g. Available, Creating)."
  value       = huaweicloud_cce_autopilot_cluster.prod_k8s.status[0].phase
}

output "kube_apiserver_endpoints" {
  description = "Access address(es) of kube-apiserver for prod_k8s cluster."
  value       = huaweicloud_cce_autopilot_cluster.prod_k8s.status[0].endpoints
}

output "platform_version" {
  description = "Cluster platform version reported by Huawei Cloud."
  value       = huaweicloud_cce_autopilot_cluster.prod_k8s.platform_version
}

output "availability_zone" {
  description = "AZ the cluster's control plane is running in."
  value       = huaweicloud_cce_autopilot_cluster.prod_k8s.az
}