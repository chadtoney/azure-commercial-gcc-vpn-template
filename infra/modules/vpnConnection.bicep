param name string
param location string
param vpnGatewayId string
param localNetworkGatewayId string
@secure()
param sharedKey string
param usePolicyBasedTrafficSelectors bool = false
param dpdTimeoutInSeconds int = 45
param ipsecPolicyProfile object = {
  enabled: false
  ikeEncryption: 'AES256'
  ikeIntegrity: 'SHA256'
  dhGroup: 'DHGroup14'
  ipsecEncryption: 'AES256'
  ipsecIntegrity: 'SHA256'
  pfsGroup: 'PFS2048'
  saLifeTimeSeconds: 27000
  saDataSizeKilobytes: 102400000
}

var ipsecPolicies = ipsecPolicyProfile.enabled
  ? [
      {
        ikeEncryption: ipsecPolicyProfile.ikeEncryption
        ikeIntegrity: ipsecPolicyProfile.ikeIntegrity
        dhGroup: ipsecPolicyProfile.dhGroup
        ipsecEncryption: ipsecPolicyProfile.ipsecEncryption
        ipsecIntegrity: ipsecPolicyProfile.ipsecIntegrity
        pfsGroup: ipsecPolicyProfile.pfsGroup
        saLifeTimeSeconds: ipsecPolicyProfile.saLifeTimeSeconds
        saDataSizeKilobytes: ipsecPolicyProfile.saDataSizeKilobytes
      }
    ]
  : []

resource connection 'Microsoft.Network/connections@2022-11-01' = {
  name: name
  location: location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpnGatewayId
      properties: {}
    }
    localNetworkGateway2: {
      id: localNetworkGatewayId
      properties: {}
    }
    sharedKey: sharedKey
    usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors
    dpdTimeoutSeconds: dpdTimeoutInSeconds
    ipsecPolicies: ipsecPolicies
  }
}

output connectionId string = connection.id
