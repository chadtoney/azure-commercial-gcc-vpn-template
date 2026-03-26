# Security Baseline (Microsoft Learn Aligned)

This baseline should be enforced for customer deployments.

## Identity and Access

- Use least-privilege Azure RBAC at the narrowest scope possible.
- Assign roles to groups, not individual users.
- Keep subscription Owner assignments limited and documented.
- Use Microsoft Entra PIM eligible assignments for privileged roles.

## Secrets Management

- Treat VPN pre-shared keys as secrets.
- Prefer Azure Key Vault with RBAC permission model enabled.
- Enable soft delete and purge protection.
- Restrict Key Vault network access (private endpoint preferred, firewall minimum).

## Network Controls

- Use non-overlapping CIDRs across Commercial and GCC.
- Keep VPN type route-based on both sides.
- Use explicit NSG rules, avoid broad allow rules.
- Do not expose direct public RDP/SSH for test VMs.

## VPN Cryptography

- Use IKEv2.
- Configure explicit IPsec/IKE policy profile where required by compliance.
- Ensure both sides use compatible algorithm suites.

## Monitoring and Detection

- Enable diagnostic logs for VPN Gateway and Key Vault.
- Forward logs to Log Analytics/SIEM as required.
- Enable Defender plans where applicable.

## Customer Handoff Requirements

- RBAC matrix and break-glass process documented.
- Secret rotation process documented.
- Validation evidence recorded after deployment.
