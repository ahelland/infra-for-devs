metadata name = 'Dev Center'
metadata description = 'Dev Center'
metadata owner = 'ahelland'

@description('Specifies the location for resources.')
param location string
@description('Name of DevCenter')
param devCenterName string
@description('Network connection id for the network the Dev Center should be attached to.')
param networkConnectionId string

@description('Tags retrieved from parameter file.')
param resourceTags object = {}
@description('DevBox definition image id.')
param image string
@description('Name of DevBox definition.')
param definitionName string = 'DevBox-8-32'
@description('DevBox definition SKU.')
param definitionSKU string = 'general_i_8c32gb256ssd_v2'
@description('DevBox definition storage type.')
param definitionStorageType string = 'ssd_256gb'

resource DevCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' = {
  name: devCenterName
  location: location
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: { }
}

//Add a default environment type
resource devEnvironment 'Microsoft.DevCenter/devcenters/environmentTypes@2023-04-01' = {
  name: 'dev'
  parent: DevCenter
  properties: {}
}

resource network 'Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01' = {
  name: '${devCenterName}-network'
  parent: DevCenter
  properties: {
    networkConnectionId: networkConnectionId
  }
}

resource DevBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-10-01-preview' = {
  parent: DevCenter
  name: definitionName
  location: location
  properties: {
    imageReference: {            
      id: '${DevCenter.id}/galleries/default/images/${image}'
    }
    sku: {
      name: definitionSKU
    }    
    osStorageType: definitionStorageType
    hibernateSupport: 'Enabled'
  }
}

@description('Id of DevCenter.')
output devCenterId string = DevCenter.id
@description('Name of the attached network.')
output devCenterAttachedNetwork string = network.name
@description('Id of the system-managed identity of the Dev Center.')
output devCenterManagedId string = DevCenter.identity.principalId
