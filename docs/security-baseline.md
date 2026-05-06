# Security Baseline (Microsoft Learn Aligned)

This baseline should be enforced for customer deployments.

## Identity and Access

- Use least-privilege Azure RBAC at the narrowest scope possible.
- Assign roles to groups, not individual users.
- Keep subscription Owner assignments limited and documented.
- Use Microsoft Entra PIM eligible assignments for privileged roles.

### Identity Federation (Cross-Tenant)

When the VPN tunnel is used to support cross-tenant access between Azure Commercial and Azure Government, the identity layer must be configured separately. See [docs/entra-b2b-guide.md](entra-b2b-guide.md) for the full setup guide.

Key baseline controls for cross-tenant identity:

- **Review and restrict guest access permissions**: Ensure guest users can only read their own profile and cannot enumerate the tenant directory. In Entra portal, navigate to **Identity** → **External Identities** → **External collaboration settings** and set guest user access to the most restrictive option appropriate for your organization.
- **Restrict who can invite guests**: Limit guest invitation rights to User Administrators or a specific group — do not allow all users to invite guests.
- **Configure explicit Cross-Tenant Access Settings (XTAP)**: Set XTAP defaults to block all, then add partner-specific organizational settings that allow only the known Commercial or GCC counterpart tenant. Do not leave XTAP at permissive Microsoft defaults.
- **Enforce MFA for all guest users**: Apply a Conditional Access policy requiring MFA for all B2B guest users accessing resources in your tenant.
- **Use time-bound PIM eligible assignments for guest privileged access**: Never grant guests permanent active privileged roles. Use PIM eligible assignments with expiration dates and require justification and MFA on activation.
- **Run quarterly access reviews for guest accounts**: Use Entra access reviews to periodically validate that guest users still require access. Configure auto-removal of access for guests not approved during review.
- **Monitor guest sign-ins**: Enable sign-in diagnostic logs and create alerts for guest user sign-ins from unexpected locations or with elevated risk signals.

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
