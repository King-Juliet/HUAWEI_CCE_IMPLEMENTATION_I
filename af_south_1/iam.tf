data "huaweicloud_identity_projects" "current" {
  name = "af-south-1"
}

output "swr_login_project_name" {
  description = "IAM project name — the <project_name> portion of the SWR docker login username (<project_name>@<AK>)."
  value       = data.huaweicloud_identity_projects.current.projects[0].name
}