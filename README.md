# Federated Fabric Customer Deployment Kit

This repository provides a customer-deployable baseline for network connectivity between Azure Commercial and Azure Government (GCC) tenants, with security-focused defaults and parameterized Infrastructure as Code.

## Architecture Summary

Azure Commercial VNet and Azure GCC VNet are connected with route-based VPN gateways on both sides, mirrored local network gateways, and IPsec connections using a shared key.

## Prerequisites

### Azure Subscriptions & Permissions

You need **two separate Azure subscriptions** with sufficient permissions:

| Requirement | Details |
|---|---|
| **Commercial Subscription** | Must have `Network Contributor` or `Owner` role on the subscription. Your gateway public IP will be deployed here. |
| **GCC Subscription** | Must have `Network Contributor` or `Owner` role on the subscription. Your gateway public IP will be deployed here. |
| **Resource Groups** | Can create new RGs during deployment, or pre-create them and assign yourself `Owner` or `Contributor` role. |

### Required Azure Role Assignments

| Task | Minimum Required Role | Scope |
|---|---|---|
| **Deploy VPN infrastructure** | `Network Contributor` | Resource Group |
| **Create/manage Key Vault** (optional) | `Key Vault Administrator` | Resource Group |
| **View deployment logs** | `Reader` | Subscription |
| **Modify existing resources** | `Owner` or `Contributor` | Resource Group |

**Note:** Some organizations use custom roles. If you encounter access denied errors, contact your subscription admin.

### Software Requirements

- **Azure CLI**: Latest version ([download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **PowerShell**: 7 or newer ([download](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell))
- **Git**: For cloning and managing this repository

### Network Requirements

- Non-overlapping CIDR ranges for Commercial and GCC VNets (e.g., `10.10.0.0/16` and `10.20.0.0/16`)
- A secure pre-shared key (PSK) for IPsec authentication
- Ability to retrieve the public IP of each deployed gateway for the cross-side configuration

### Pre-Existing Services

Before deploying, ensure the following **exist or will be created**:

| Item | Status | Notes |
|---|---|---|
| **Subscription** | ✓ Must exist | Two subscriptions required, already active in your Azure account |
| **Resource Group** | ✓ Will be created | Script creates RG automatically if it doesn't exist |
| **VNet** | ✓ Will be created | Deployed by this template with specified address space |
| **Subnets** | ✓ Will be created | Gateway subnet (GatewaySubnet name required) and workload subnet |
| **VPN Gateways** | ✓ Will be created | Route-based gateways with public IPs |
| **Key Vault** (optional) | ✓ Will be created | Only if `CREATE_KEY_VAULT=true` in .env |

**You do not need to pre-create:** VNets, subnets, gateways, connections, or local network gateways.

## What This Implements

- Route-based Site-to-Site VPN between Commercial and GCC VNets.
- Parameterized deployment for each cloud side (run independently).
- Optional Key Vault creation for secret management patterns.
- Deployment and validation scripts for repeatable customer onboarding.

## What This Does Not Implement

- Fabric tenant-level feature parity workarounds.
- Unsupported cross-tenant features identified in docs.

## Repository Structure

- `infra/main-commercial.bicep`: Commercial-side deployment.
- `infra/main-gcc.bicep`: GCC-side deployment.
- `infra/modules/`: Reusable Bicep modules.
- `infra/parameters/`: Sanitized example parameter files (for reference).
- `scripts/`: Deployment and validation scripts.
- `docs/validation-runbook.md`: Operational validation checklist.
- `docs/security-baseline.md`: Security controls to apply and verify.
- `.env.example`: Configuration template for your deployment values.

## Quick Start (3 Steps)

### Step 1: Create Your Configuration File

Copy `.env.example` to `.env` in the repository root:

```bash
cp .env.example .env
```

### Step 2: Fill In Your Values

Edit `.env` with your Azure subscription details. Open the file in your editor and search-replace placeholder values:

```env
# Example values (use your actual values):
COMMERCIAL_SUBSCRIPTION_ID = "12345678-1234-1234-1234-123456789012"
COMMERCIAL_TENANT_ID = "abcdef00-abcd-1234-abcd-abcdef001234"
COMMERCIAL_RESOURCE_GROUP = "my-commercial-rg"
COMMERCIAL_ADDRESS_PREFIX = "10.10.0.0/16"
COMMERCIAL_REMOTE_GATEWAY_IP = "203.0.113.10"  # GCC gateway IP (get after GCC deployment)

GCC_SUBSCRIPTION_ID = "87654321-4321-4321-4321-210987654321"
GCC_TENANT_ID = "fedcba00-fedc-4321-fedc-fedcba000000"
GCC_RESOURCE_GROUP = "my-gcc-rg"
GCC_ADDRESS_PREFIX = "10.20.0.0/16"
GCC_REMOTE_GATEWAY_IP = "198.51.100.10"  # Commercial gateway IP (get after Commercial deployment)

SHARED_KEY = "your-super-secure-preshared-key-here"
NAMING_PREFIX = "myorg"
```

**Tip:** If a field has `PASTE_YOUR_...`, it still needs a real value. GatewayIPs come after the first deployment.

### Step 3: Deploy

**Deploy Commercial side first:**

```powershell
./scripts/deploy-commercial.ps1
```

This will:
1. Load your `.env` configuration
2. Create the resource group (if needed)
3. Deploy VPN infrastructure
4. **Show the Commercial gateway public IP at the end** ← copy this for GCC config

**Update GCC_REMOTE_GATEWAY_IP** in `.env` with the Commercial gateway IP from Step 3, then deploy GCC:

```powershell
./scripts/deploy-gcc.ps1
```

**Update COMMERCIAL_REMOTE_GATEWAY_IP** in `.env` with the GCC gateway IP from this deployment, then redeploy Commercial:

```powershell
./scripts/deploy-commercial.ps1
```

**Validate the tunnel:**

```powershell
./scripts/validate-vpn.ps1 -Cloud AzureCloud -SubscriptionId "YOUR_COMMERCIAL_SUB_ID" -ResourceGroupName "YOUR_RG" -ConnectionName "$(cat .env | grep NAMING_PREFIX | cut -d' ' -f3 | tr -d '"')-comm-to-gcc"
```

See `docs/validation-runbook.md` for detailed post-deployment checks.

## Environment File (.env) Reference

The `.env` file contains:

- **COMMERCIAL_*** : Commercial-side configuration (subscription, network, VPN)
- **GCC_*** : GCC-side configuration (subscription, network, VPN)
- **SHARED_KEY** : IPsec pre-shared key (treat as a secret)
- **NAMING_PREFIX** : Resource naming prefix (e.g., "myorg" → "myorg-vpngw")
- **CREATE_KEY_VAULT** : Whether to create a Key Vault for secret management

All fields are required. Do not commit `.env` to git (already in `.gitignore`).

## Deployment Scripts

| Script | Cloud | Command |
|---|---|---|
| `deploy-commercial.ps1` | Azure Commercial | `./scripts/deploy-commercial.ps1` |
| `deploy-gcc.ps1` | Azure Government | `./scripts/deploy-gcc.ps1` |
| `validate-vpn.ps1` | Both | `./scripts/validate-vpn.ps1 -Cloud AzureCloud ...` |
| `Load-Env.ps1` | Helper | Called automatically by deploy scripts |

Deploy scripts automatically load `.env` and pass values to Bicep templates. No manual parameter entry needed.

## Security and Publish Safety

- **Never commit `.env`** to git (shared keys, subscription IDs)
- **Keep local operational notes** in `notes/local-environment.md` (ignored by git)
- **Store shared keys securely** in CI/CD secrets or Key Vault, not in code
- **Review `docs/security-baseline.md`** before production deployment

## Security Notes

- Use least-privilege RBAC and group-based assignments
- Store shared keys in Key Vault or secure CI/CD variables
- Avoid exposing test VMs to public RDP/SSH
- Validate NSGs for explicit allow rules only

See `docs/security-baseline.md` for details.

## Troubleshooting

If deployment fails:

1. **Check .env syntax**: Ensure all values use `KEY = "VALUE"` format (with quotes)
2. **Verify Azure authentication**: Run `az account show` to confirm you're logged into the correct subscription
3. **Check role permissions**: See Permissions table above; contact your admin if you lack `Network Contributor` role
4. **Review Bicep template errors**: The script will show Azure deployment errors
5. **Check address space overlap**: Ensure COMMERCIAL and GCC address prefixes don't overlap

See `docs/validation-runbook.md` for additional diagnostics.

## Parameter Files (Legacy Reference)

For reference, sanitized example parameter files are available:
- `infra/parameters/commercial.example.parameters.json`
- `infra/parameters/gcc.example.parameters.json`

**Recommended approach:** Use `.env` files instead (simpler and more maintainable).

## Additional Docs

- [Validation Runbook](docs/validation-runbook.md): Post-deployment health checks
- [Security Baseline](docs/security-baseline.md): Microsoft Learn-aligned controls
- [Entra B2B Guide](docs/entra-b2b-guide.md): Cross-tenant identity federation setup for Commercial ↔ GCC
- [Contributing Guide](CONTRIBUTING.md): How to contribute to this repository
- [Troubleshooting](TROUBLESHOOTING.md): Common issues and solutions
