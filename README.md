# AWS Cloud Security & Networking Infrastructure

This repository contains the complete network topography and infrastructure components for a secure, segregated multi-AZ AWS environment. The project implements a custom VPC architecture and dynamic subnet matrix allocation using Terraform.

## Project Structure

```text
├── terraform.tfvars        # Input variable assignment mapping parameters
├── variables.tf            # Top-level root environment variable definitions
├── main.tf                 # Primary deployment orchestrator (Loops, SGs, ENIs, EC2)
├── providers.tf            # Terraform and AWS provider engine declarations
└── modules/
    ├── vpc/
    │   ├── main.tf        # Base VPC and core gateway resources
    │   ├── variables.tf   # VPC boundary inputs
    │   └── outputs.tf     # Network boundary IDs passed up to root layer
    └── subnets/
        ├── main.tf        # Centralized subnet definition using conditional maps
        └── variables.tf   # Single-module subnet matrix configuration inputs
```

## Infrastructure Specifications Deployed

### 1. VPC & Core Edge Gateways
* **Custom VPC Topology**: Provisioned inside the Sydney (`ap-southeast-2`) region using the `10.160.0.0/16` CIDR block boundary.
* **Internet Gateway (IGW)**: Deployed and explicitly attached to handle external network access.
* **Default VPC Elimination**: Isolated deployment paths to completely bypass default regional networking.

### 2. Multi-AZ Subnet Matrix
Subnets are dynamically mapped using a structured variable loop configuration matching assignment rules:
* **LAN10** (`10.160.10.0/24`) – Public Subnet | Availability Zone `a`
* **LAN20** (`10.160.20.0/24`) – Private Subnet | Availability Zone `a`
* **LAN30** (`10.160.30.0/24`) – Private Subnet | Availability Zone `a`
* **LAN40** (`10.160.40.0/24`) – Private Subnet | Availability Zone `b`
* **LAN50** (`10.160.50.0/24`) – Private Subnet | Availability Zone `c`

### 3. Route Table Architecture
* **Public Routing**: Bound to LAN10 to route default traffic (`0.0.0.0/0`) via the Internet Gateway.
* **Private Routing**: Grouped LAN20, LAN30, LAN40, and LAN50. This table is explicitly designated as the **Main Route Table** for the VPC.

### 4. Interface Management & Security
* **Management Security Group**: Provisioned with structural rules to control management control plane access.
* **Elastic Network Interfaces (ENIs)**: Pre-allocated across the private subnets. **Source/Destination Checks are Disabled** to support next-generation inline firewall inspection.

---

## Technical Reflection & Architectural Answers

### Why LAN40 and LAN50 Cannot Attach to the Same FortiGate Instance
AWS EC2 structural logic dictates that an Elastic Network Interface (ENI) can only be attached to an EC2 compute instance if **both resources reside inside the exact same Availability Zone (AZ)**. Because the primary FortiGate firewall instance is launched within **AZ `a`** to bridge paths for LAN20 and LAN30, it is physically impossible to map or connect network interfaces residing in LAN40 (**AZ `b`**) or LAN50 (**AZ `c`**).

### High-Availability (HA) Best Practices for Multi-AZ Firewalls
To establish proper fault tolerance for production workloads spanning multiple availability zones:
* Deploy a clustered **Active-Passive or Active-Active Firewall Dual Pair** across separate zones (e.g., Firewall-A in AZ-A, Firewall-B in AZ-B).
* Utilise an **AWS Transit Gateway (TGW)** or an **AWS Network Load Balancer** sitting upstream from the firewalls. This allows traffic routing tables to automatically adapt and shift traffic across physical AZ boundaries if an entire data center zone experiences an unexpected outage.
