variable "vpc_cidr" { type = string }
variable "vpc_name" { type = string }
variable "igw_name" { type = string }
variable "subnets_config" {
  type = map(object({
    cidr      = string
    az        = string
    is_public = bool
  }))
}
variable "aws_region" {
  type        = string
  description = "The AWS region to deploy all resources into"
}
