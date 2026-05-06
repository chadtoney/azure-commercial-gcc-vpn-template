# Entra B2B Guide: Cross-Tenant Identity Federation for Azure Commercial ↔ GCC

## Overview

Establishing a VPN tunnel between Azure Commercial and Azure Government (GCC) solves the **network layer** — packets can now flow between the two environments. However, network connectivity and identity federation are **separate, independent layers**. Users and service principals still need to authenticate and be authorized in both tenants before they can access resources across the boundary.

This guide covers the **identity layer**: configuring Microsoft Entra B2B collaboration between an Azure Commercial tenant and an Azure Government (GCC) tenant so that users in one tenant can be granted access to resources in the other.

> **Important:** Entra B2B configuration requires manual admin consent steps in **both** tenants and cannot be scripted or templated safely. All steps in this guide must be performed by a Global Administrator or Privileged Role Administrator in each tenant.

---

## Layer Separation — Network vs. Identity

| Layer | Handled By | This Guide? |
|---|---|---|
| Network connectivity (VPN tunnel, routing, IPsec) | This repository's Bicep templates and scripts | No — see main `README.md` |
| Identity federation (guest users, cross-tenant access) | Microsoft Entra B2B / Cross-Tenant Access Settings | **Yes** |

Both layers are required for end-to-end access. The VPN provides the private network path; Entra B2B provides the authenticated identity path. Configure the VPN first, then layer identity federation on top.

---

## Azure Government B2B Limitations

Azure Government (GCC) has **restricted B2B support** compared to Azure Commercial. Before designing your identity federation architecture, be aware of the following known limitations:

| Feature | Azure Commercial | Azure Government (GCC) |
|---|---|---|
| Entra B2B guest invitations | ✅ Fully supported | ✅ Supported (with caveats — see below) |
| Cross-Tenant Access Settings (XTAP) | ✅ Fully supported | ✅ Supported |
| B2B Direct Connect (Teams shared channels) | ✅ Supported | ❌ Not available in Azure Government |
| Microsoft Entra External ID (workforce) | ✅ Generally available | ⚠️ Partial availability; verify in Azure Government docs |
| Microsoft Entra External ID (customer) | ✅ Generally available | ❌ Not available in Azure Government |
| SAML/WS-Fed federation with external IdPs | ✅ Supported | ⚠️ Limited; verify per-IdP support |
| Guest user OTP (email one-time passcode) | ✅ Supported | ✅ Supported |
| Self-service guest redemption via MyApps | ✅ Supported | ⚠️ May have portal differences; test before relying on it |
| Cross-cloud B2B (Commercial ↔ Government) | ✅ Technically possible | ⚠️ Requires explicit XTAP configuration; not enabled by default |
| Entitlement Management for cross-cloud | ✅ Supported | ⚠️ Limited; access packages may not work cross-cloud |

> **Key takeaway:** Cross-cloud B2B (a Commercial tenant inviting users from a Government tenant, or vice versa) is possible but requires deliberate configuration and has feature gaps compared to same-cloud B2B. Plan your architecture around these limitations.

### Additional Government-Specific Caveats

- **Guest redemption flow**: Government tenant guests may be redirected to `https://portal.azure.us` instead of `https://portal.azure.com` during redemption. Ensure your invitation emails and documentation reflect the correct portal URL.
- **Conditional Access**: Some Conditional Access features (e.g., geographic/country-based named locations, specific authentication strength combinations) may not yet be available in Azure Government. Verify current availability in the [Azure Government services availability list](https://aka.ms/azgovservices).
- **Microsoft 365 integration**: If your B2B use case involves Microsoft 365 collaboration (SharePoint, Teams), note that Teams shared channels (B2B Direct Connect) are not available in Azure Government. Use regular guest access instead.
- **Token issuance**: Cross-cloud B2B tokens are issued by the resource tenant's authority. Users authenticating from a Commercial account into a Government resource will use the Government tenant's token endpoint (`login.microsoftonline.us`).

---

## Cross-Tenant Access Settings (XTAP)

Cross-Tenant Access Settings control whether your tenant allows **inbound** (from other tenants into yours) and **outbound** (from your tenant into other tenants) B2B collaboration. By default, both are allowed by Microsoft's defaults — but for security, you should configure **explicit partner-specific policies** that restrict access to only your known counterpart tenant.

### Step 1: Configure XTAP in the Azure Commercial Tenant

1. Sign in to the [Entra portal](https://entra.microsoft.com) as a Global Administrator or Security Administrator.
2. Navigate to **Identity** → **External Identities** → **Cross-tenant access settings**.
3. Select the **Organizational settings** tab.
4. Click **+ Add organization** and enter the **Tenant ID** of your GCC (Government) tenant.
5. Once added, click on the organization row to configure it:

   **Inbound access** (Government users coming into your Commercial tenant):
   - Under **B2B collaboration** → **External users and groups**: Select **Allow access** and scope to specific security groups if possible (rather than all users).
   - Under **B2B collaboration** → **Applications**: Select **Allow access** and restrict to specific application IDs that cross-tenant users need.
   - Under **Trust settings**: Enable **Trust multifactor authentication from Microsoft Entra tenant** if you want to honor MFA already completed in the GCC tenant (avoids double-MFA prompts).
   - Enable **Trust compliant devices** and **Trust Microsoft Entra hybrid joined devices** only if devices in the GCC tenant meet your Commercial tenant's compliance standards.

   **Outbound access** (Commercial users going into the Government tenant):
   - Under **B2B collaboration** → **External users and groups**: Select **Allow access** and scope to specific security groups.
   - Under **B2B collaboration** → **Applications**: Select **Allow access** and restrict to specific application IDs.

6. Click **Save**.

### Step 2: Configure XTAP in the Azure Government (GCC) Tenant

1. Sign in to the [Azure Government Entra portal](https://entra.microsoft.us) as a Global Administrator or Security Administrator.
2. Navigate to **Identity** → **External Identities** → **Cross-tenant access settings**.
3. Select the **Organizational settings** tab.
4. Click **+ Add organization** and enter the **Tenant ID** of your Azure Commercial tenant.
5. Configure inbound and outbound settings symmetrically with Step 1 (mirror the Commercial-side configuration).
6. Click **Save**.

> **Both tenants must configure XTAP.** If only one side is configured, cross-tenant B2B will not work. The inbound settings on the **resource tenant** determine whether the guest can access resources; the outbound settings on the **home tenant** determine whether users are allowed to use their identity externally.

### Default vs. Organizational Settings

- **Default settings** apply to all tenants not explicitly listed in Organizational settings. It is a Microsoft security best practice to leave defaults set to **Block** (or restrict) and create explicit allow policies for only your known partner tenants.
- To harden defaults: In the **Default settings** tab, set both inbound and outbound to **Block all** — then use Organizational settings for your specific GCC/Commercial partner tenant to allow the necessary access.

---

## Guest User Invitation Flow

### Inviting a GCC (Government) User into the Commercial Tenant

1. Sign in to [entra.microsoft.com](https://entra.microsoft.com) as a User Administrator or Global Administrator.
2. Navigate to **Identity** → **Users** → **All users** → **+ Invite external user**.
3. Fill in:
   - **Email address**: The user's GCC account email (e.g., `user@agency.gov`)
   - **Display name**: Descriptive name for easy identification
   - **Message**: Include context and the correct redemption URL if needed
4. Under **Properties**, review the **User type** (should be `Guest`).
5. Click **Invite**. The user receives an email invitation.

### Redemption Process

1. The invited user receives an email from Microsoft with a redemption link.
2. The user clicks the link. If XTAP is correctly configured, they will be prompted to sign in with their **GCC credentials** (authenticating against `login.microsoftonline.us`).
3. On first redemption, the user accepts a permissions consent screen showing what the inviting tenant will have access to about their account.
4. After redemption, the user appears as a **Guest** in the inviting tenant's user list.

> **Government-to-Commercial redemption note:** Government users redeeming invitations into a Commercial tenant must authenticate at `login.microsoftonline.us` (their home authority). Ensure that the guest is aware of this and that any Conditional Access policies in the Commercial tenant do not inadvertently block Government cloud sign-ins.

### Scoping Guest Access to Specific Apps or Resources

Rather than granting guests broad access, use one or more of these mechanisms:

- **App role assignments**: Assign the guest to a specific application role within a registered app. The guest can only access that app, not the broader tenant directory.
- **Azure RBAC role assignments**: Assign the guest to a resource-group-scoped or resource-scoped role (e.g., `Reader` on a specific resource group). Avoid subscription-scope assignments for guests.
- **Entra groups**: Add the guest to a security group that already has the required app role or Azure RBAC role. Manage access by managing group membership.
- **Entitlement Management access packages**: (Where available in Government) Create an access package that bundles the required app roles and group memberships, and assign it to the guest. This supports time-limited access and access reviews.

---

## Conditional Access Considerations for Cross-Tenant Users

Conditional Access (CA) policies apply at the **resource tenant** — where the application or resource lives. When a guest user from the other cloud tenant accesses a resource in your tenant, your CA policies evaluate their sign-in.

### Recommended CA Policies for Cross-Tenant Guest Users

| Policy | Recommended Setting | Notes |
|---|---|---|
| **Require MFA** | Require MFA for all guests | If XTAP trust for MFA is enabled, MFA satisfied in the home tenant counts; otherwise the resource tenant prompts again |
| **Require compliant or hybrid-joined device** | Enable only if guest devices can meet compliance | GCC devices may not satisfy Commercial Intune compliance; verify before enabling |
| **Sign-in risk** | Block high risk, require MFA for medium risk | Entra ID Protection evaluates sign-in signals for guest users |
| **User risk** | Block high risk | User risk signals may be limited for cross-cloud guests |
| **Named locations / IP ranges** | Restrict to expected IP ranges if possible | VPN tunnel IP ranges can be used as named locations to restrict access to private-network-only sign-ins |
| **Authentication strengths** | Require phishing-resistant MFA (FIDO2 or CBA) for privileged access | Verify Azure Government Conditional Access supports the specific auth strength you require |

### Creating a Guest-Specific CA Policy

1. In Entra portal, navigate to **Protection** → **Conditional Access** → **+ New policy**.
2. Under **Users**: Select **Guest or external users** → **B2B collaboration guest users**.
3. Under **Cloud apps or actions**: Target the specific applications guests will access (or **All cloud apps** with exclusions).
4. Under **Conditions**: Optionally add sign-in risk, device platform, or named locations.
5. Under **Grant**: Select **Require multifactor authentication** (and any other controls).
6. Enable the policy in **Report-only** mode first; validate with test users before switching to **On**.

> **Avoid blocking all guests by default.** Use targeted policies that apply only to the cross-tenant guest user group or specific guest accounts, to avoid unintended lockout.

---

## Entra PIM for Cross-Tenant Privileged Access

If guest users from the partner cloud need **privileged roles** (e.g., to manage Azure resources in the resource tenant), use Microsoft Entra Privileged Identity Management (PIM) to manage those assignments.

### Configuring PIM Eligible Assignments for Guest Users

1. In Entra portal, navigate to **Identity governance** → **Privileged Identity Management** → **Azure resources** (or **Entra roles** for directory roles).
2. Select the resource (subscription, resource group, etc.) or the directory role.
3. Under **Assignments**, click **+ Add assignments**.
4. Under **Member type**: Select the guest user from the directory (they must have redeemed their invitation and exist as a Guest object).
5. Set **Assignment type** to **Eligible** (not Active) — this requires the guest to explicitly activate the role when needed.
6. Set a **Duration** (time-bound eligible assignments are a security best practice; avoid permanent eligible assignments for guests).
7. Configure **Activation settings** for that role:
   - Require justification on activation
   - Require MFA on activation
   - Require approval for high-privilege roles (e.g., Owner, Contributor at subscription scope)

### Access Reviews for Guest Privileged Access

Configure periodic access reviews to ensure guest privileged access remains appropriate:

1. Navigate to **Identity governance** → **Access reviews** → **+ New access review**.
2. Scope the review to **Guest users** in the specific role or group.
3. Set review frequency (e.g., quarterly for privileged roles).
4. Assign reviewers — ideally the guest's sponsor in the resource tenant or a resource owner.
5. Configure **auto-apply results**: Remove access for guests who are not approved, to reduce standing access risk.

---

## Known Limitations and Workarounds

| Limitation | Impact | Workaround |
|---|---|---|
| B2B Direct Connect not available in Azure Government | Teams shared channels cannot be used with GCC guests | Use standard B2B guest access for Teams; users join channels as guests rather than using shared channels |
| Cross-cloud guest redemption may fail if XTAP is not configured on both sides | Guest invitation email sent but user cannot redeem | Ensure both the Commercial and GCC tenants have explicit XTAP organizational settings for each other |
| Government users authenticating into Commercial may receive MFA prompts even if already MFA-satisfied | User experience friction | Enable XTAP trust for MFA from the GCC tenant in the Commercial XTAP organizational settings |
| Entra External ID (customer) not available in Azure Government | Cannot use External ID customer scenarios from a GCC tenant | Use workforce B2B (regular guest invitations) instead |
| Entitlement Management access packages may not work cross-cloud | Cannot use access packages for automated guest provisioning | Manually assign guests to groups/app roles; use access reviews for lifecycle management |
| Conditional Access named locations may not include Government cloud auth endpoints by default | CA policies using IP-based conditions may not behave as expected for cross-cloud sign-ins | Test CA policies thoroughly with Government guest accounts; use sign-in logs to verify expected behavior |
| Guest users from Government tenants may see Commercial-tenant URLs | Confusion about which portal to use | Provide explicit onboarding instructions to guests with the correct portal URLs and sign-in flow |
| Some Azure Government regions do not have parity with Commercial for Entra features | Features available in Commercial may not exist in Government | Consult the [Azure Government services availability list](https://aka.ms/azgovservices) before designing a feature-dependent solution |

---

## Admin Consent Requirements

> **This configuration cannot be scripted or automated safely.**

The following steps require **manual action by a Global Administrator** in each tenant:

1. **XTAP configuration**: Must be performed by a Global Administrator or Security Administrator in each tenant's Entra portal. There is no ARM/Bicep resource type for XTAP organizational settings.
2. **Guest invitation authorization**: A User Administrator or Global Administrator in the resource tenant must send invitations or authorize a self-service invitation flow.
3. **Guest redemption consent**: The guest user must personally complete the redemption flow and consent to the permissions presented during redemption. This is a user action and cannot be pre-consented by an admin on behalf of a cross-cloud guest.
4. **Conditional Access policy activation**: CA policies should be validated in report-only mode before enforcement; this requires an admin to review sign-in logs and explicitly enable each policy.
5. **PIM role activation approvals**: If approvals are required for PIM activations, approvers must be configured in each tenant and must be available to approve requests in real time.

---

## References

- [Microsoft Entra B2B collaboration overview](https://learn.microsoft.com/en-us/entra/external-id/what-is-b2b)
- [Cross-tenant access settings overview](https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview)
- [Configure cross-tenant access settings](https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration)
- [B2B collaboration for Azure Government](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-active-directory)
- [Azure Government services availability](https://aka.ms/azgovservices)
- [Entra PIM for Azure resources](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-resource-roles-assign-roles)
- [Conditional Access for B2B users](https://learn.microsoft.com/en-us/entra/external-id/authentication-conditional-access)
- [Entra access reviews](https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview)
