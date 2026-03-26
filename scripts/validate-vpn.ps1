param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('AzureCloud', 'AzureUSGovernment')]
  [string]$Cloud,
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,
  [Parameter(Mandatory = $true)]
  [string]$ConnectionName,
  [string]$GatewayName
)

$ErrorActionPreference = 'Stop'

az cloud set --name $Cloud | Out-Null
az account set --subscription $SubscriptionId

Write-Host "Checking connection status for $ConnectionName..."
az network vpn-connection show `
  --resource-group $ResourceGroupName `
  --name $ConnectionName `
  --query "{name:name, status:connectionStatus, egress:egressBytesTransferred, ingress:ingressBytesTransferred}" `
  --output table

if ($GatewayName) {
  Write-Host "Checking BGP peer status for gateway $GatewayName..."
  az network vnet-gateway list-bgp-peer-status `
    --resource-group $ResourceGroupName `
    --name $GatewayName `
    --output table
}

Write-Host 'Validation query complete. Continue with route and NSG validation from docs/validation-runbook.md.'
