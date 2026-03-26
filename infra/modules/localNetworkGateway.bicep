param name string
param location string
param gatewayIpAddress string
param remoteAddressPrefixes array

resource lng 'Microsoft.Network/localNetworkGateways@2023-11-01' = {
  name: name
  location: location
  properties: {
    gatewayIpAddress: gatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: remoteAddressPrefixes
    }
  }
}

output localNetworkGatewayId string = lng.id
