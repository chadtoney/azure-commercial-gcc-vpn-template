# Federated Fabric Customer Deployment Kit

This repository provides a customer-deployable baseline for network connectivity between Azure Commercial and Azure Government (GCC) tenants, with security-focused defaults and parameterized Infrastructure as Code.

## Architecture Summary

Azure Commercial VNet and Azure GCC VNet are connected with route-based VPN gateways on both sides, mirrored local network gateways, and IPsec connections using a shared key.

## Prerequisites

- Azure CLI installed and authenticated to both tenant contexts.
- Access to both subscriptions with rights to deploy networking resources.
- PowerShell 7+ for deployment scripts.
- Non-overlapping CIDR ranges for both VNets.
- A secure pre-shared key (PSK) available at deployment time.

## What This Implements

- Route-based Site-to-Site VPN between Commercial and GCC VNets.
- Parameterized deployment for each cloud side (run independently).
- Optional Key Vault creation for secret management patterns.
- Deployment and validation scripts for repeatable customer onboarding.

## Current Verified Topology

- Commercial and GCC VPN resources can be deployed in separate resource groups.
- Workload resources may live in different resource groups than VPN resources.
- Use `scripts/validate-vpn.ps1` and Azure CLI inventory commands to confirm your active environment layout.

## What This Does Not Implement

- Fabric tenant-level feature parity workarounds.
- Unsupported cross-tenant features identified in `federated-fabric-validation-findings.md`.

## Repository Structure

- `infra/main-commercial.bicep`: Commercial-side deployment.
- `infra/main-gcc.bicep`: GCC-side deployment.
- `infra/modules/`: Reusable Bicep modules.
- `infra/parameters/`: Environment parameter files and sanitized examples.
- `scripts/`: Deployment and validation scripts.
- `docs/validation-runbook.md`: Operational validation checklist.
- `docs/security-baseline.md`: Security controls to apply and verify.

## Parameter File Strategy

- Commit safe example files:
	- `infra/parameters/commercial.example.parameters.json`
	- `infra/parameters/gcc.example.parameters.json`
- Keep local environment-tuned files out of git (see `.gitignore`).

## Required Customer Inputs

- Subscription IDs for Commercial and GCC.
- Tenant IDs for both sides.
- Resource group names.
- Regions.
- Non-overlapping address spaces for both VNets.
- Remote gateway public IP for each side.
- Pre-shared key (PSK) value provided securely at deployment time.
- Naming prefix and tagging metadata.

## Quick Start

1. Copy each `*.example.parameters.json` to local `*.dev.parameters.json` and fill in tenant, address space, and remote IP values.
2. Deploy one side first (for example Commercial) to create gateway public IP.
3. Deploy the other side using the first side gateway public IP.
4. Update the first side's `remoteGatewayPublicIp` if needed and redeploy.
5. Run `scripts/validate-vpn.ps1` to verify tunnel and routing status.

## Deployment Scripts

- Commercial:
	- `scripts/deploy-commercial.ps1`
	- Default parameters file: `infra/parameters/commercial.example.parameters.json`
- GCC:
	- `scripts/deploy-gcc.ps1`
	- Default parameters file: `infra/parameters/gcc.example.parameters.json`

Both scripts require `SubscriptionId`, `ResourceGroupName`, and `SharedKey`.

## Security and Publish Safety

- Do not commit real tenant IDs, user identities, shared keys, or environment snapshots.
- Keep local operational notes in `notes/local-environment.md` (ignored by git).
- Keep helper comparison outputs and binary draft artifacts out of git.
- Review `docs/security-baseline.md` before production deployment.

## Security Notes

- Use least-privilege RBAC and group-based assignments.
- Store shared keys in Key Vault or secure CI/CD variables.
- Avoid exposing test VMs to public RDP/SSH.
- Validate NSGs for explicit allow rules only.

See `docs/security-baseline.md` for details.

## Additional Docs

- `docs/validation-runbook.md`
- `federated-fabric-validation-findings.md`
