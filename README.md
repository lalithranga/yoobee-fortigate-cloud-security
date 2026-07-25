# AWS Hybrid Cloud Security Architecture with FortiGate NGFW
### 🛡️ Cyber Security Capstone Project | Lalith

---

## 👨‍💻 Project Overview
This repository contains the design, implementation, and automation blueprints for a secure, highly available network on AWS using a **FortiGate Next-Generation Firewall (NGFW)**. 

Developed by **Lalith** for **CCC603: Cyber Security in Cloud (30 Credits)**, this capstone project demonstrates how to enforce enterprise compliance (**NIST CSF, ISO 27001, CIS Benchmarks**) using **Terraform (IaC)**, **Ansible CLI**, and **AWS Lambda** serverless cost controls.

---

## 🏗️ Core Network Topology (Sydney Region: `ap-southeast-2`)

* **Custom VPC:** `Lalith-VPC` configured with a private `10.160.0.0/16` IP block.
* **Perimeter Gateway:** `Lalith_IGW` attached to the VPC for managed public internet access.
* **Hardened Perimeter:** Default AWS VPC deleted to eliminate unmonitored baseline routes.

### 📁 Segmented Subnet Infrastructure
* **LAN10 (`10.160.10.0/24`):** Public DMZ subnet housing public-facing firewall interfaces.
* **LAN20 & LAN30 (`10.160.20.0/24`, `10.160.30.0/24`):** Private workload zones in **AZ-a**.
* **LAN40 & LAN50 (`10.160.40.0/24`, `10.160.50.0/24`):** Private zones in **AZ-b & AZ-c** for data continuity.

### 🛣️ Routing & Security Group Rules
* **`Public_Route_Table`:** Points default `0.0.0.0/0` traffic directly out through `Lalith_IGW`.
* **`Private_Route_Table`:** Set as the Main Route Table. Forces all private workload traffic directly to the **FortiGate Internal ENI** for absolute security scrubbing.
* **Security Constraints:** **Source/Destination Check disabled** on all firewall ENIs. Administrative access locked down using `Management_SG`.

---

## ⚙️ DevOps Automation & Financial Governance

### 🚀 1. Infrastructure as Code (Terraform)
* Pre-scripts the automatic creation of the VPC, subnets, route table attachments, ENIs, and the FortiGate instance (`t3.medium`).
* *[Placeholder: Link to `/terraform` folder scripts]*

### 🛠️ 2. Configuration Management (Ansible CLI)
* Establishes secure remote **SSH sessions** directly into FortiOS to configure security policies.
* Automates a midnight **Cron Job** to extract the firewall state and backup the file to an encrypted **AWS S3 Bucket**.

### ⚡ 3. Serverless Cost Controls (AWS Lambda)
* A Python-based **AWS Lambda function** triggered by EventBridge automatically starts the firewall instance at **9:00 AM NZT** and stops it at **5:00 PM NZT** daily to minimize idle cloud resource costs.

---

## 🔬 Engineering Reflections & Insights

* **AZ Boundaries:** `LAN40` (AZ-b) and `LAN50` (AZ-c) cannot attach directly to the primary FortiGate instance because AWS EC2 instances can only hold network interfaces (ENIs) residing in their **exact same Availability Zone** (AZ-a).
* **Multi-AZ Continuity:** Production workloads require an **Active-Passive clustered pair** split across distinct zones. If a zone fails, the standby peer updates the VPC route table targets via AWS API calls in **< 15 seconds (RTO Target)** with **0 configuration data loss (RPO Target)**.

---

## 📁 Repository Map
```text
├── terraform/               # IaC scripts for custom VPC topography & subnets
│   ├── main.tf              
│   └── variables.tf
├── ansible/                 # Playbooks for automated FortiOS backups
│   ├── inventory/hosts.ini  
│   └── backup_playbook.yml  
├── lambda/                  # Serverless cost schedules (9 AM - 5 PM NZT)
│   └── instance_scheduler.py
└── documentation/
    ├── Executive_Report.pdf  # 3,000-Word Compliance & Risk Report
    └── Demonstration.mp4     # 5-7 minute video walkthrough walkthrough
```
