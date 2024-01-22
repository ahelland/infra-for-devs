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

resource devCenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  scope: rg_devc
  name: 'devCenter-01'
}

module DevProject '../main.bicep' = {
  scope: rg_devc
  name: 'devProject'  
  params: {
    resourceTags: resourceTags
    devBoxDefinitionName: 'DevBox-8-32'
    devCenterId: devCenter.id
    devPoolName: 'devPool-01'    
    location: location
    networkConnectionName: 'devConnection'
    projectName: 'iac'
    deploymentTargetId: subscription().id
  }
}
