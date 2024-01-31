targetScope = 'subscription'

@description('Location for Container App.')
param location string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

resource rg_cae 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'rg-cae'
}

resource containerenvironment 'Microsoft.App/managedEnvironments@2023-05-02-preview' existing = {
  scope: rg_cae
  name: 'cae-01'
}

module helloApp '../main.bicep' = {
  scope: rg_cae
  name: 'container-app-hello'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: 'eshop.azurecr.io'
    containerImage: 'helloword:latest'
    targetPort: 8080
    identityName: 'eshop-user-mi'
    name: 'hello'
  }
}
