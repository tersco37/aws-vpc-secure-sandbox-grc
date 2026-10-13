# AWS VPC Network Security & Risk Assessment Report

## 1. Executive Summary & Assessment Scope
This report documents the security assessment performed on the core VPC infrastructure (`main.tf`). The objective was to evaluate network boundaries, egress/ingress control logic, logging controls, and risk trade-offs against enterprise security standards (**NIST SP 800-53** and **ISO/IEC 27001**).

---

## 2. Technical Component Review

### A. Routing & Network Boundaries
* **Public Subnets**: Explicitly routed to the Internet Gateway (`0.0.0.0/0`). Designed for edge load balancers or public-facing entry points.
* **Private Subnets**: Completely unrouted to the internet. Provides a strong air-gapped isolation boundary for databases and application tiers.

### B. Security Groups & State Management
* **Default Security Group Hardening**: Standard AWS defaults permit all intra-group traffic and unrestricted egress. This deployment explicitly strips all rules (`[]`), creating a fail-secure posture for unassigned interfaces.

### C. Network ACLs (NACLs) & Subnet Protection
* **Perimeter Defense**: Relies on default stateless NACLs paired with stateful Security Groups. While sufficient for standard environments, high-assurance frameworks recommend explicit subnet-level deny rules for anomalous traffic protocols.

---

## 3. Exposure Risk & Least-Privilege Analysis

### Finding 1: Private Subnet Egress Limitations
* **Observation**: Private subnets lack a NAT Gateway or VPC Endpoint configuration.
* **Risk Evaluation**: While maximum network isolation is achieved, backend workloads cannot perform software updates or connect to AWS services (e.g., CloudWatch, Systems Manager).
* **Recommendation**: Deploy **AWS VPC Interface Endpoints (PrivateLink)** to allow secure access to management APIs without opening outbound internet paths.

### Finding 2: Hardened Default Security Group Baseline
* **Observation**: Default security group ingress/egress rules are cleared.
* **Security Assessment**: **Exemplary Posture**. Prevents shadow-IT or unassigned resources from inheriting broad communication rules.

### Finding 3: Log Retention Window (Cost Trade-off)
* **Observation**: VPC Flow Logs are capped at 30 days (`retention_in_days = 30`) with active Checkov exceptions (`CKV_AWS_338`, `CKV_AWS_158`).
* **Risk Decision**: Accepted business exception for sandbox cost optimization. In production, logs should transition to S3 with Glacier archival for long-term audit compliance.

---

## 4. Remediation & Hardening Roadmap
1. Provision SSM VPC Endpoints for session-based management access without open SSH/RDP ports.
2. Implement application-specific security groups following strict protocol/port boundaries.
