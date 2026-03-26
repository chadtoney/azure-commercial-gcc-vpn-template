# Validation Runbook

Use this checklist after each deployment.

## 1. Tunnel Health

- Verify both VPN connections show `Connected`.
- Confirm both sides are using intended connection type and policy settings.

## 2. Route Verification

- Verify effective routes on test NICs include remote VNet CIDRs.
- Confirm there are no overlapping route conflicts.

## 3. Security Verification

- Validate NSGs do not contain broad allow rules.
- Validate Key Vault has purge protection and soft delete enabled.
- Validate privileged role assignments follow approved RBAC model.

## 4. Connectivity Testing

- Test VM-to-VM connectivity over ICMP if allowed.
- Test TCP flows required for workload (RDP/SSH/HTTPS as applicable).
- Record pass/fail with timestamp and tester.

## 5. Performance Expectations

- Compare observed throughput against expected VPN SKU baseline.
- If requirements exceed S2S VPN profile, evaluate ExpressRoute.

## 6. Artifacts to Save

- Connection status outputs.
- Effective route outputs.
- NSG rule snapshots.
- Any incident/troubleshooting notes.
