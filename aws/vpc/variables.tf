variable "aws_region" {
  default     = "us-east-2"
  type        = string
  description = "AWS region to deploy to"
}

variable "prefix" {
  default     = "chaney-dev"
  type        = string
  description = "Name tag prefix"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "VPC CIDR block"
}

# TODO variable subnet count and size
variable "subnet_internal_1_cidr" {
  default     = "10.0.1.0/24"
  type        = string
  description = "VPC internal subnet CIDR 1"
}

variable "subnet_internal_2_cidr" {
  default     = "10.0.2.0/24"
  type        = string
  description = "VPC internal subnet CIDR 2"
}

variable "subnet_external_1_cidr" {
  default     = "10.0.11.0/24"
  type        = string
  description = "VPC external subnet CIDR 1"
}

variable "subnet_external_2_cidr" {
  default     = "10.0.12.0/24"
  type        = string
  description = "VPC external subnet CIDR 2"
}

# TODO this doesn't scale!
variable "subnet_az_primary" {
  default     = "us-east-2a"
  type        = string
  description = "The AZ to use for the primary subnet"
}

variable "subnet_az_secondary" {
  default     = "us-east-2b"
  type        = string
  description = "The AZ to use for the secondary subnet"
}
