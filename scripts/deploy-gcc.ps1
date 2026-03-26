param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,
  [Parameter(Mandatory = $true)]
  [securestring]$SharedKey,
  [string]$Location = 'usgovvirginia',
  [string]$ParametersFile = '../infra/parameters/gcc.example.parameters.json'
)

$ErrorActionPreference = 'Stop'

Write-Host 'Setting cloud to AzureUSGovernment...'
az cloud set --name AzureUSGovernment | Out-Null

Write-Host "Setting subscription $SubscriptionId..."
az account set --subscription $SubscriptionId

if (-not (az group exists --name $ResourceGroupName | ConvertFrom-Json)) {
  Write-Host "Creating resource group $ResourceGroupName in $Location..."
  az group create --name $ResourceGroupName --location $Location | Out-Null
}

$plainSharedKey = [System.Net.NetworkCredential]::new('', $SharedKey).Password

Write-Host 'Deploying GCC side...'
az deployment group create `
  --name "gcc-$(Get-Date -Format yyyyMMddHHmmss)" `
  --resource-group $ResourceGroupName `
  --template-file ../infra/main-gcc.bicep `
  --parameters "@$ParametersFile" `
  --parameters sharedKey="$plainSharedKey"

Write-Host 'GCC deployment completed.'
