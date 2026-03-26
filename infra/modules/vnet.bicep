param name string
param location string
param addressPrefixes array
param gatewaySubnetPrefix string
param workloadSubnetPrefix string = '10.0.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: 'workload'
        properties: {
          addressPrefix: workloadSubnetPrefix
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output gatewaySubnetId string = '${vnet.id}/subnets/GatewaySubnet'
output workloadSubnetId string = '${vnet.id}/subnets/workload'
