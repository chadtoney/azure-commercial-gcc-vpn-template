param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,
  [Parameter(Mandatory = $true)]
  [securestring]$SharedKey,
  [string]$Location = 'eastus2',
  [string]$ParametersFile = '../infra/parameters/commercial.example.parameters.json'
)

$ErrorActionPreference = 'Stop'

Write-Host 'Setting cloud to AzureCloud...'
az cloud set --name AzureCloud | Out-Null

Write-Host "Setting subscription $SubscriptionId..."
az account set --subscription $SubscriptionId

if (-not (az group exists --name $ResourceGroupName | ConvertFrom-Json)) {
  Write-Host "Creating resource group $ResourceGroupName in $Location..."
  az group create --name $ResourceGroupName --location $Location | Out-Null
}

$plainSharedKey = [System.Net.NetworkCredential]::new('', $SharedKey).Password

Write-Host 'Deploying commercial side...'
az deployment group create `
  --name "commercial-$(Get-Date -Format yyyyMMddHHmmss)" `
  --resource-group $ResourceGroupName `
  --template-file ../infra/main-commercial.bicep `
  --parameters "@$ParametersFile" `
  --parameters sharedKey="$plainSharedKey"

Write-Host 'Commercial deployment completed.'
