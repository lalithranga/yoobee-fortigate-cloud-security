# AWS Cloud Security & Networking Infrastructure — FortiGate Deployment

This repository contains the complete Infrastructure as Code (IaC) configuration using Terraform to design, deploy, and verify a secure, multi-AZ cloud network architecture in the Sydney (`ap-southeast-2`) region. The environment features a custom VPC, segmented public/private subnets using single-module boolean conditional architecture patterns, and integrations for a FortiGate Next-Generation Firewall (NGFW).

## Architectural Specifications & Requirements

### 1. Network Setup & VPC Design
* Custom VPC deployed with CIDR block `10.160.0.0/16`.
* Connected to an external Internet Gateway (IGW) for public edge routing.
* The default regional VPC is completely bypassed/isolated.

### 2. Subnet Matrix Configuration
All subnets are instantiated dynamically via a loop structure passing explicit parameters:
* **LAN10** (`10.160.10.0/24`) – Public Subnet (Availability Zone `a`)
* **LAN20** (`10.160.20.0/24`) – Private Subnet (Availability Zone `a`)
* **LAN30** (`10.160.30.0/24`) – Private Subnet (Availability Zone `a`)
* **LAN40** (`10.160.40.0/24`) – Private Subnet (Availability Zone `b`)
* **LAN50** (`10.160.50.0/24`) – Private Subnet (Availability Zone `c`)

### 3. Route Tables & Border Security
* **Public Route Table**: Bound to LAN10; handles edge traffic routing straight to the Internet Gateway (`0.0.0.0/0`).
* **Private Route Table**: Bound to LAN20, LAN30, LAN40, and LAN50; designated explicitly as the VPC's main route table.
* **Management Security Group**: Configured to process management traffic protocols.
* **Elastic Network Interfaces (ENIs)**: Created for private segments with **Source/Destination Checks Disabled** to permit true inline firewall inspection.

---

## Directory Structure

```text
├── main.tf                 # Primary deployment orchestrator (Loops, SGs, ENIs, EC2)
├── variables.tf            # Top-level root environment variable definitions
├── terraform.tfvars        # Input variable assignment mapping parameters
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

---

## Local Deployment & Verification Workflow

### 1. Set Up Environment Authentication
Because this project utilizes protected sandbox execution contexts (such as AWS Academy), temporary credentials must be explicitly mapped to override execution restrictions. Download your session variables and input them directly into your shell environment:

```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="IQoJ..."
```

Verify your authentication identity bounds before processing deployment cycles:
```bash
aws sts get-caller-identity
```

### 2. Run the Terraform Lifecycle Engine
Navigate directly into the root folder structure and execute initialization steps:

```bash
# Initialize project workspace and download external providers
terraform init

# Generate a blueprint plan to verify resources before creation
terraform plan

# Apply and execute the target deployment state onto the cloud region
terraform apply --auto-approve
```

---

## Architecture Reflection & Technical Review

### 1. Why LAN40 and LAN50 Cannot Attach to the Same FortiGate Instance
AWS EC2 structural rules dictate that an elastic interface (ENI) can only be attached to an EC2 instance if **both resources reside inside the exact same Availability Zone (AZ)**. 

Because the primary FortiGate firewall compute resource is launched inside **AZ `a`** to properly bridge network paths for LAN20 and LAN30, it is physically impossible to map or mount network attachments directly to interfaces residing within LAN40 (**AZ `b`**) or LAN50 (**AZ `c`**). 

### 2. High-Availability (HA) Best Practices for Multi-AZ Firewalls
To ensure operational survivability and fault tolerance for multi-AZ workloads, the following steps are required:
* Deploy a clustered **Active-Passive or Active-Active Firewall Dual Pair** spanning across separate operational availability zones (e.g., Firewall-A in AZ-A, Firewall-B in AZ-B).
* Utilise **AWS Transit Gateway (TGW)** or an **AWS Route 53 Network Load Balancer** sitting ahead of the firewall cluster. This allows traffic routing states to automatically shift across independent AZ boundaries without service drops if a single physical data center cluster experiences an outage.
