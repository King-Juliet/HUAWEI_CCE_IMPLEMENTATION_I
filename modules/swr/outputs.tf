output "organization_id" {
  description = "ID of the SWR organization."
  value       = huaweicloud_swr_organization.this.id
}

output "login_server" {
  description = "Registry URL used for `docker login` / `docker push` (e.g. swr.af-south-1.myhuaweicloud.com)."
  value       = huaweicloud_swr_organization.this.login_server
}

output "repository_paths" {
  description = "Map of repository name -> full docker pull/push address, for wiring into CI pipelines or Kubernetes manifests."
  value       = { for k, v in huaweicloud_swr_repository.this : k => v.path }
}

output "repository_internal_paths" {
  description = "Map of repository name -> cluster-internal pull address (used by CCE pods pulling privately via enable_swr_image_access, rather than over the public internet)."
  value       = { for k, v in huaweicloud_swr_repository.this : k => v.internal_path }
}

output "repository_ids" {
  description = "Map of repository name -> numeric repository ID."
  value       = { for k, v in huaweicloud_swr_repository.this : k => v.repository_id }
}
