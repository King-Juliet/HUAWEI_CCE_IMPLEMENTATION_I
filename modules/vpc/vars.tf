variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_owner" {
  description = "Owner of the VPC (for tagging purposes)"
  type        = string
}

variable "vpc_project" {
  description = "Project associated with the VPC (for tagging purposes)"
  type        = string
}

variable "vpc_environment" {
  description = "Environment for the VPC (for tagging purposes)"
  type        = string
}

variable "vpc_managed_by" {
  description = "Entity managing the VPC (for tagging purposes)"
  type        = string
  default     = "Terraform"
}