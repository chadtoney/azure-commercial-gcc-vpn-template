# Troubleshooting

## VPN Connection Not Connected

- Confirm both sides use route-based gateways.
- Confirm shared key matches exactly on both sides.
- Confirm each local network gateway points to the remote gateway public IP.
- Confirm non-overlapping CIDR ranges.

## Deployment Succeeds But Traffic Fails

- Check effective routes on test NICs.
- Confirm NSGs allow required test protocols.
- Validate remote address prefixes in local network gateways.

## Parameter Mismatch Symptoms

- Stuck connection status or intermittent connectivity usually indicates remote IP/CIDR mismatch.
- Re-check `remoteGatewayPublicIp` and `remoteAddressPrefixes` on both sides.

## Cloud Context Errors

- Commercial deployment requires `AzureCloud`.
- GCC deployment requires `AzureUSGovernment`.
- Re-run login if subscription context changes.
