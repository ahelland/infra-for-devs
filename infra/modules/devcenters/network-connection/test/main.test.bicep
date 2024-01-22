targetScope = 'subscription'

param location string = 'westeurope'

param resourceTags object = {
  value: {
    IaC: 'Bicep'
    Environment: 'Test' 
  }
}

resource rg_devc 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-devcenter'
  location: location
  tags: resourceTags
}

module networkConnection '../main.bicep' = {
  scope: rg_devc
  name: 'devConnection'
  params: {
    resourceTags: resourceTags
    connectionName: 'devConnection'
    location: location
    snetId: 'snet-devbox-01'
  }
}
