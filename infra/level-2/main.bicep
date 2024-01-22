targetScope = 'subscription'

@description('Azure region to deploy resources into.')
param location string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

resource rg_vnet 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-eshop-vnet'
  location: location
  tags: resourceTags
}

resource rg_dns 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-eshop-dns'
  location: location
  tags: resourceTags
}

param vnetName string = 'eshop-vnet-weu'
module vnet 'br/public:network/virtual-network:1.1.3' = {
  scope: rg_vnet
  name: 'eshop-vnet-weu'
  params: {
    name: vnetName
    location: location    
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-devbox-01'
        addressPrefix: '10.1.1.0/24'
        privateEndpointNetworkPolicies: 'Enabled'
      }
      {
        name: 'snet-cae-01'
        addressPrefix: '10.1.2.0/24'
        privateEndpointNetworkPolicies: 'Enabled'
        delegations: [
          {            
            name: 'Microsoft.App.environments'
            properties: {
              serviceName: 'Microsoft.App/environments'
            }
            type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
          }
        ]
      }
      {
        name: 'snet-pe-01'
        addressPrefix: '10.1.3.0/24'
        privateEndpointNetworkPolicies: 'Enabled'
      }    
    ]
  }
}

//We import the vnet just created to be able to read the properties
resource vnet_import 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  scope: rg_vnet
  name: vnetName
}
//Private endpoint DNS
module dnsZoneACR '../modules/network/private-dns-zone/main.bicep' = {
  scope: rg_dns
  name: 'eshop-private-dns-acr'
  params: {
    resourceTags: resourceTags
    registrationEnabled: false
    vnetId: vnet_import.id
    vnetName: vnetName
    zoneName: 'privatelink.azurecr.io'
  }
}
