## **Exposure Risks & Least-Privilege Analysis**

An evaluation of the infrastructure code (`main.tf`) against cloud security best practices reveals strong foundational hardening, alongside explicit risk trade-offs typical of a cost-optimized sandbox design.

### **Finding 1: Private Subnet Isolation & Outbound Egress Constraints**
* **Technical State**: The architecture provisions private subnets (`10.0.101.0/24`, `10.0.102.0/24`) without an explicit NAT Gateway or private route table mapping in the current scope.
* **Risk & Exposure Analysis**: While this ensures maximum isolation (zero inbound or outbound internet routing), workloads placed within these subnets are completely cut off from external endpoints. They cannot pull package updates or communicate with external APIs directly.
* **Least-Privilege Recommendation**: 
  * If backend workloads require updates, introduce a managed NAT Gateway or leverage **AWS VPC Endpoints (AWS PrivateLink)** for services like SSM and CloudWatch. This maintains zero public inbound exposure while allowing secure, controlled outbound connectivity.

### **Finding 2: Hardened Default Security Group Baseline**
* **Technical State**: The configuration explicitly overrides the risky AWS default security group behavior by nulling all ingress and egress rules (`ingress = []`, `egress = []`).
* **Security Evaluation**: **Exemplary Posture**. In unmanaged AWS environments, the default security group often acts as an open catch-all vector if instances are launched without an explicit SG assignment. Forcing an empty baseline mitigates accidental exposure.
* **Recommendation**: Maintain this standard across all environments. Ensure any future application tiers utilize dedicated, tightly scoped security groups rather than falling back to default allocations.

### **Finding 3: Log Retention & Forensic Window Trade-off**
* **Technical State**: VPC Flow Logs are written to CloudWatch with a retention period capped at 30 days (`retention_in_days = 30`), accompanied by formal Checkov exceptions (`CKV_AWS_338`, `CKV_AWS_158`).
* **Risk & Exposure Analysis**: A 30-day retention window satisfies immediate operational and short-term audit requirements, but restricts long-term forensic investigations, threat hunting, and compliance audits that mandate 90 to 365+ days of log history.
* **Recommendation**: Acceptable for sandbox and non-production environments to control CloudWatch storage costs. For enterprise or production iterations, migrate log destination targets to an S3 bucket configured with **S3 Object Lock** and tiered lifecycle transition rules (e.g., Glacier Flexible Retrieval) for cost-effective long-term retention.

---

## 4. Remediation & Hardening Roadmap

1. **Implement VPC Endpoints**: Configure interface endpoints for AWS Systems Manager (SSM) to facilitate zero-trust, secure management access to private instances without requiring a public bastion host or internet gateway route.
2. **Expand Egress Filtering**: As application tiers are added, replace open egress allowances with specific port-level constraints (e.g., limiting database subnets to internal communication ports only).
