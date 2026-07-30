# root main.tf

module "base_vpc" {
  source         = "./modules/vpc"
  vpc_cidr_block = "10.160.0.0/16"
  vpc_name       = "Lalith-VPC"   
  igw_name       = "Lalith_IGW"  
}
