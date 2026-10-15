#swr — private image registry for the frontend/backend app images deployed onto CCE.
#Paired with enable_swr_image_access = true on the cluster (cce.tf), so pods pull these
#images over a private VPC endpoint rather than the public internet.
#
#NOTE: organization_name must be globally unique across ALL Huawei Cloud tenants, not just
#this account — "juliet-cce" may already be taken. Confirm/change before first apply.

module "juliet_swr" {
  source = "../modules/swr"

  organization_name = "juliet-cce"

  # Names match the actual image paths used throughout k8s/*.yaml and test_app/README.md
  # (imto-test-frontend / imto-test-backend) — keep these in sync if either side changes.
  repositories = {
    frontend = {
      name        = "imto-test-frontend"
      description = "Frontend app served to users via ELB and Envoy Gateway"
      category    = "other"
      is_public   = false
    }
    backend = {
      name        = "imto-test-backend"
      description = "Backend app — talks to third-party systems via the NAT Gateway"
      category    = "other"
      is_public   = false
    }
  }
}

output "swr_login_server" {
  description = "Registry URL for `docker login`/`docker push`."
  value       = module.juliet_swr.login_server
}

output "swr_repository_paths" {
  description = "Full pull/push address per repository, for CI pipelines and Kubernetes manifests."
  value       = module.juliet_swr.repository_paths
}
