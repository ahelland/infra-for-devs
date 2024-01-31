metadata name = 'Container App Service'
metadata description = 'Container App Service'
metadata owner = 'ahelland'

@description('Specifies the location for resources.')
param location string = resourceGroup().location
@description('Tags retrieved from parameter file.')
param resourceTags object = {}
@description('Name of the service-')
param serviceName string
@description('Type of service.')
@allowed([
  'redis'
  'postgres'
])
param serviceType string
@description('Id of container environment to deploy to.')
param containerAppEnvironmentId string

resource containerService 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: serviceName
    location: location
    tags: resourceTags
    properties: {
      environmentId: containerAppEnvironmentId
      configuration: {
        service: {
            type: serviceType
        }
      }
    }
  }

@description('The id of the service.')
output id string = containerService.id
