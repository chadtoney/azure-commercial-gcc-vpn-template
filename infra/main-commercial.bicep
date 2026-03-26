targetScope = 'resourceGroup'

@description('Naming prefix for all resources in this deployment.')
param prefix string
param location string = resourceGroup().location
param tenantId string
param vnetAddressPrefixes array = [
  '10.10.0.0/16'
]
param gatewaySubnetPrefix string = '10.10.255.0/27'
param workloadSubnetPrefix string = '10.10.1.0/24'
param vpnGatewaySku string = 'VpnGw1'
param remoteGatewayPublicIp string
param remoteAddressPrefixes array = [
  '10.20.0.0/16'
]
@secure()
param sharedKey string
param createKeyVault bool = true
param ipsecPolicyProfile object = {
  enabled: true
  ikeEncryption: 'AES256'
  ikeIntegrity: 'SHA256'
  dhGroup: 'DHGroup14'
  ipsecEncryption: 'AES256'
  ipsecIntegrity: 'SHA256'
  pfsGroup: 'PFS2048'
  saLifeTimeSeconds: 27000
  saDataSizeKilobytes: 102400000
}

module vnet './modules/vnet.bicep' = {
  name: 'commercial-vnet'
  params: {
    name: '${prefix}-vnet'
    location: location
    addressPrefixes: vnetAddressPrefixes
    gatewaySubnetPrefix: gatewaySubnetPrefix
    workloadSubnetPrefix: workloadSubnetPrefix
  }
}

module gateway './modules/vpnGateway.bicep' = {
  name: 'commercial-vpngw'
  params: {
    gatewayName: '${prefix}-vpngw'
    publicIpName: '${prefix}-vpngw-pip'
    location: location
    gatewaySubnetId: vnet.outputs.gatewaySubnetId
    gatewaySku: vpnGatewaySku
  }
}

module remoteLng './modules/localNetworkGateway.bicep' = {
  name: 'commercial-remote-lng'
  params: {
    name: '${prefix}-remote-lng'
    location: location
    gatewayIpAddress: remoteGatewayPublicIp
    remoteAddressPrefixes: remoteAddressPrefixes
  }
}

module vpnConnection './modules/vpnConnection.bicep' = {
  name: 'commercial-vpn-connection'
  params: {
    name: '${prefix}-to-remote'
    location: location
    vpnGatewayId: gateway.outputs.vpnGatewayId
    localNetworkGatewayId: remoteLng.outputs.localNetworkGatewayId
    sharedKey: sharedKey
    usePolicyBasedTrafficSelectors: false
    dpdTimeoutInSeconds: 45
    ipsecPolicyProfile: ipsecPolicyProfile
  }
}

module keyVault './modules/keyVault.bicep' = if (createKeyVault) {
  name: 'commercial-kv'
  params: {
    name: toLower(replace('${prefix}-kv', '_', '-'))
    location: location
    tenantId: tenantId
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
  }
}

output vpnGatewayPublicIp string = gateway.outputs.publicIpAddress
output vpnGatewayId string = gateway.outputs.vpnGatewayId
output localVnetId string = vnet.outputs.vnetId
output keyVaultName string = createKeyVault ? toLower(replace('${prefix}-kv', '_', '-')) : ''
