variable "vpc_cidr_block" {
  type        = string
  description = "The IPv4 CIDR block range for the custom VPC (e.g., 10.160.0.0/16)"
}

variable "vpc_name" {
  type        = string
  description = "The specific Name tag for the custom VPC (e.g., Lalith-VPC)"
}

variable "igw_name" {
  type        = string
  description = "The specific Name tag for the attached Internet Gateway (e.g., Lalith_IGW)"
}
