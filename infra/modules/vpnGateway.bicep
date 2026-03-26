param gatewayName string
param publicIpName string
param location string
param gatewaySubnetId string
param gatewaySku string = 'VpnGw1'

resource gatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2022-11-01' = {
  name: gatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    enableBgp: false
    activeActive: false
    ipConfigurations: [
      {
        name: 'gw-ipconfig'
        properties: {
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: gatewayPublicIp.id
          }
        }
      }
    ]
  }
}

output vpnGatewayId string = vpnGateway.id
output publicIpResourceId string = gatewayPublicIp.id
output publicIpAddress string = gatewayPublicIp.properties.ipAddress
