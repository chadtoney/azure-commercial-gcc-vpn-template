param(
  [string]$SubscriptionId,
  [string]$ResourceGroupName,
  [securestring]$SharedKey,
  [string]$EnvFilePath = '.env'
)

$ErrorActionPreference = 'Stop'

# Load environment configuration
Write-Host 'Loading environment configuration...' -ForegroundColor Cyan
$config = & "$PSScriptRoot/Load-Env.ps1" -EnvFilePath $EnvFilePath

if ($null -eq $config) {
  Write-Error "Failed to load configuration from $EnvFilePath"
  exit 1
}

# Use parameters if provided, otherwise use values from .env
$subId = if ($SubscriptionId) { $SubscriptionId } else { $config['GCC_SUBSCRIPTION_ID'] }
$rgName = if ($ResourceGroupName) { $ResourceGroupName } else { $config['GCC_RESOURCE_GROUP'] }
$location = $config['GCC_REGION']
$prefix = $config['NAMING_PREFIX']

# Handle SharedKey: if provided as parameter use it, otherwise read from config
if (-not $SharedKey) {
  $SharedKey = ConvertTo-SecureString $config['SHARED_KEY'] -AsPlainText -Force
}

$plainSharedKey = [System.Net.NetworkCredential]::new('', $SharedKey).Password

# Build parameters hashtable from .env config
$bicepParams = @{
  'prefix' = $prefix
  'location' = $location
  'tenantId' = $config['GCC_TENANT_ID']
  'vnetAddressPrefixes' = @($config['GCC_ADDRESS_PREFIX'])
  'gatewaySubnetPrefix' = $config['GCC_GATEWAY_SUBNET']
  'workloadSubnetPrefix' = $config['GCC_WORKLOAD_SUBNET']
  'vpnGatewaySku' = $config['GCC_GATEWAY_SKU']
  'remoteGatewayPublicIp' = $config['GCC_REMOTE_GATEWAY_IP']
  'remoteAddressPrefixes' = @($config['GCC_REMOTE_ADDRESS_PREFIX'])
  'sharedKey' = $plainSharedKey
  'createKeyVault' = [bool]::Parse($config['CREATE_KEY_VAULT'])
}

Write-Host 'Setting cloud to AzureUSGovernment...' -ForegroundColor Cyan
az cloud set --name AzureUSGovernment | Out-Null

Write-Host "Setting subscription $subId..." -ForegroundColor Cyan
az account set --subscription $subId | Out-Null

if (-not (az group exists --name $rgName | ConvertFrom-Json)) {
  Write-Host "Creating resource group $rgName in $location..." -ForegroundColor Yellow
  az group create --name $rgName --location $location | Out-Null
}

Write-Host 'Deploying GCC VPN infrastructure...' -ForegroundColor Green
$deploymentName = "gcc-vpn-$(Get-Date -Format yyyyMMddHHmmss)"

$params = $bicepParams.GetEnumerator() | ForEach-Object { "--parameters $($_.Key)='$($_.Value)'" }

az deployment group create `
  --name $deploymentName `
  --resource-group $rgName `
  --template-file "$PSScriptRoot/../infra/main-gcc.bicep" `
  @params | Out-Null

Write-Host 'GCC VPN deployment completed successfully.' -ForegroundColor Green

# Retrieve deployed gateway public IP
Write-Host 'Retrieving deployed gateway public IP...' -ForegroundColor Cyan
$publicIp = az network public-ip show `
  --resource-group $rgName `
  --name "$prefix-vpngw-pip" `
  --query "ipAddress" `
  --output tsv

Write-Host "Gateway Public IP (use for remote side): $publicIp" -ForegroundColor Yellow
