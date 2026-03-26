param name string
param location string
param tenantId string
param enablePurgeProtection bool = true
param softDeleteRetentionInDays int = 90
param publicNetworkAccess string = 'Disabled'
param skuName string = 'standard'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: enablePurgeProtection
    softDeleteRetentionInDays: softDeleteRetentionInDays
    publicNetworkAccess: publicNetworkAccess
    sku: {
      family: 'A'
      name: skuName
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: publicNetworkAccess == 'Disabled' ? 'Deny' : 'Allow'
    }
  }
}

output keyVaultId string = kv.id
output keyVaultName string = kv.name
