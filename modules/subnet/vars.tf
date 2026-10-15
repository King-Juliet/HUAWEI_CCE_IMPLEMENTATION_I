variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "subnet_gateway_ip" {
  description = "Gateway IP for the subnet (should be within the subnet CIDR)"
  type        = string

}

variable "vpc_id" {
  description = "ID of the VPC where subnet will be created"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for the subnet"
  type        = string
}

variable "subnet_owner" {
  description = "Owner of the subnet (for tagging purposes)"
  type        = string
}

variable "subnet_project" {
  description = "Project associated with the subnet (for tagging purposes)"
  type        = string
}

variable "subnet_environment" {
  description = "Environment for the subnet (for tagging purposes)"
  type        = string
}

variable "subnet_managed_by" {
  description = "Entity managing the subnet (for tagging purposes)"
  type        = string
  default     = "Terraform"
}