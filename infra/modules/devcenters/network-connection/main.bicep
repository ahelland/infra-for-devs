metadata name = 'Dev Box Network Connection'
metadata description = 'Dev Box Network Connection'
metadata owner = 'ahelland'

@description('Specifies the location for resources.')
param location string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}
@description('Name of Network Connection')
param connectionName string
@description('Subnet for network connection.')
param snetId string

resource NetworkConnection 'Microsoft.DevCenter/networkConnections@2023-10-01-preview' = {
  name: connectionName
  location: location
  tags: resourceTags
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: snetId
    domainName: ''
    organizationUnit: ''
    domainUsername: ''
    networkingResourceGroupName: 'NI_${connectionName}_westeurope'
  }
}

@description('Id of network connection.')
output id string = NetworkConnection.id
@description('Name of network connection.')
output connectionName string = NetworkConnection.name
