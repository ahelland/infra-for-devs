metadata name = 'Dev Box Project'
metadata description = 'Dev Box Project with Pool.'
metadata owner = 'ahelland'

@description('Specifies the location for resources.')
param location string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}
@description('Id of the DevCenter to attach project to.')
param devCenterId string
@description('Name of project.')
param projectName string
@description('Name of DevBox pool.')
param devPoolName string
@description('Name of network connection to attach to.')
param networkConnectionName string
@description('Name of DevBox definition.')
param devBoxDefinitionName string
@description('License Type of DevBox.')
param licenseType string = 'Windows_Client'
@allowed([
  'Enabled'
  'Disabled'
])
@description('Status of local admin account.')
param localAdministrator string = 'Enabled'
@description('SubscriptionId the environment will be mapped to.')
param deploymentTargetId string

resource Project 'Microsoft.DevCenter/projects@2023-10-01-preview' = {
  name: projectName
  tags: resourceTags
  location: location
  properties: {    
    devCenterId: devCenterId
  }
}

//Add a Dev environment
resource devEnvironment 'Microsoft.DevCenter/projects/environmentTypes@2023-04-01' = {
  name: 'dev'
  location: location  
  parent: Project
  identity: {
    type: 'SystemAssigned'    
  }
  properties: {    
    deploymentTargetId: deploymentTargetId
    status: 'Enabled'    
  }
}

resource DevPool 'Microsoft.DevCenter/projects/pools@2023-10-01-preview' = {
  parent: Project
  name: devPoolName
  tags: resourceTags
  location: location
  properties: {
    devBoxDefinitionName: devBoxDefinitionName
    networkConnectionName: networkConnectionName
    licenseType: licenseType
    localAdministrator: localAdministrator    
  }
}

@description('Id of the system-managed identity for the dev environment.')
output devEnvironmentManagedId string = devEnvironment.identity.principalId
