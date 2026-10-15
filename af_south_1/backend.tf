# terraform {
#   # Local backend for testing — state is just a file on this machine, no OBS/S3 involved.
#   # Swap back to the "s3" block below once you're done testing and want shared/remote state.
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
  terraform {
  backend "s3" {
    bucket     = "juliet-terraform-backend"
    key        = "terraform/state.tfstate"
    region     = "af-south-1"

    endpoints = {
      s3 = "https://obs.af-south-1.myhuaweicloud.com"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = false
    skip_s3_checksum            = true
  }
}