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

resource NetworkConnection 'Microsoft.DevCenter/networkConnections@2023-10-01-preview' existing = {
  scope: rg_devc
  name: 'devcenter-network-connection'
}

module devCenter '../main.bicep' = {
  scope: rg_devc
  name: 'devcenter'
  params: {
    resourceTags: resourceTags
    devCenterName: 'devCenter-01'      
    location: location
    image: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
    networkConnectionId: NetworkConnection.id
  }
}
