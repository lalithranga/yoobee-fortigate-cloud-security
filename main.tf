# 1. Base VPC Deployment
module "base_vpc" {
  source         = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr
  vpc_name       = var.vpc_name
  igw_name       = var.igw_name
}

# 2. Subnet Matrix Construction via Single Module Loop
module "subnets" {
  source   = "./modules/subnets"
  for_each = var.subnets_config

  vpc_id            = module.base_vpc.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  subnet_name       = each.key
  is_public         = each.value.is_public
  route_table_id    = each.value.is_public ? module.base_vpc.public_route_table_id : module.base_vpc.private_route_table_id
}

# 3. Management Security Group (Allow all inbound initially)
resource "aws_security_group" "management_sg" {
  name        = "Management_SG"
  description = "Management Security Group for assignment"
  vpc_id      = module.base_vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Management_SG" }
}

# 4. Elastic Network Interfaces (ENIs) for LAN20 through LAN50
resource "aws_network_interface" "private_enis" {
  for_each = toset(["LAN20", "LAN30", "LAN40", "LAN50"])

  subnet_id         = module.subnets[each.key].subnet_id
  security_groups   = [aws_security_group.management_sg.id]
  source_dest_check = false # Requirement 4: Disable source/dest check

  tags = { Name = "${each.key}_ENI" }
}

# 5. FortiGate Next-Generation Firewall Instance (t3.medium)
resource "aws_instance" "fortigate" {
  ami           = "ami-0453303666d691e84" # Placeholder: Make sure to replace with the real FortiGate AMI ID from Sydney Marketplace
  instance_type = "t3.medium"

  # Primary network interface (LAN20)
  network_interface {
    network_interface_id = aws_network_interface.private_enis["LAN20"].id
    device_index         = 0
  }

  tags = { Name = "FortiGate_Firewall" }
}

# Attaching LAN30 ENI as the secondary firewall interface
resource "aws_network_interface_attachment" "lan30_attach" {
  instance_id          = aws_instance.fortigate.id
  network_interface_id = aws_network_interface.private_enis["LAN30"].id
  device_index         = 1
}

# 6. Elastic IP Allocation and Association for External Firewall Access
resource "aws_eip" "fortigate_eip" {
  domain = "vpc"
  tags   = { Name = "FortiGate_EIP" }
}

resource "aws_eip_association" "eip_assoc" {
  network_interface_id = aws_network_interface.private_enis["LAN20"].id
  allocation_id        = aws_eip.fortigate_eip.id
}
