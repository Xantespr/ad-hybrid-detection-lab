
# Active Directory Detection Lab

A hybrid cybersecurity lab for detecting suspicious Active Directory activity using Microsoft Sentinel.

## Technologies
- Windows Server 2025 / Active Directory
- Windows 11
- Oracle VirtualBox
- Azure Arc and Azure Monitor Agent
- Log Analytics Workspace
- Microsoft Sentinel
- KQL and Bicep

## Detection Rules

| Rule | MITRE ATT&CK |
|---|---|
| Account Creation | T1136.002 |
| Group Membership Change | T1098 |
| Password Spraying | T1110.003 |
| Kerberoasting | T1558.003 |

## Experiment Results

32 controlled experiments were performed.

| TP | FP | FN | TN | Recall |
|---|---|---|---|---|
| 20 | 6 | 0 | 6 | 100% |

The results reflect controlled laboratory scenarios and do not represent production detection effectiveness!

## Documentation
- [On-premises Infrastructure](docs/01_on_prem_infrastructure.md)
- [Security Auditing](docs/02_security_auditing.md)
- [Azure Integration](docs/03_azure_integration.md)
- [Detection Rules](docs/04_detection_rules.md)
- [Experiment Results](simulations/results.md)

## Detection Rules as Code

Bicep templates are available in `infrastructure/azure/rules/`.
