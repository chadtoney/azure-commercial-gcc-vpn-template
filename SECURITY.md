# Security Policy

## Scope

This repository contains infrastructure templates and scripts for Azure Commercial <-> GCC VPN baseline deployments.

## Reporting Security Issues

Do not create public issues for potential security vulnerabilities.

Report privately to the repository maintainers with:
- A clear description of the issue.
- Affected file paths and deployment impact.
- Reproduction steps and suggested mitigation.

## Secure Usage Guidance

- Never commit production tenant IDs, user identities, shared keys, or connection snapshots.
- Keep shared keys out of files; pass them as secure parameters at deployment time.
- Use least-privilege RBAC and group-based role assignments.
- Verify Key Vault purge protection and soft delete before go-live.
- Validate NSGs to avoid broad inbound rules.

See `docs/security-baseline.md` for the baseline controls.
