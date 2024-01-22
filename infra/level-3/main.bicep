targetScope = 'subscription'

@description('Azure region to deploy resources into.')
param location string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

resource rg_vnet 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'rg-eshop-vnet'
}

resource rg_dns 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'rg-eshop-dns'
}

resource rg_cae 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-eshop-cae'
  location: location
  tags: resourceTags
}

param vnetName string = 'eshop-vnet-weu'
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  scope: rg_vnet
  name: vnetName
}

resource rg_acr 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-eshop-acr'  
  location: location
  tags: resourceTags
}

param subId string = subscription().id
param acrName string = 'acr${uniqueString(subId)}'
//Private Endpoints require Premium SKU
param acrSku string = 'Premium'
param acrManagedIdentity string = 'SystemAssigned'

module containerRegistry '../modules/containers/container-registry/main.bicep' = {
  scope: rg_acr
  name: acrName
  params: {
    resourceTags: resourceTags
    acrName: acrName
    acrSku: acrSku
    adminUserEnabled: false
    anonymousPullEnabled: false 
    location: location
    managedIdentity: acrManagedIdentity
    publicNetworkAccess: 'Disabled'
  }
}

//Private endpoints (two required for ACR)
module peAcr 'acr-pe-endpoints.bicep' = {
  scope: rg_acr
  name: 'pe-acr'
  params: {
    resourceTags: resourceTags
    location: location
    peName: 'pe-acr'
    serviceConnectionGroupIds: 'registry'
    serviceConnectionId: containerRegistry.outputs.id
    snetId: '${vnet.id}/subnets/snet-pe-01'
  }
}

module acr_dns_pe_0 '../modules/network/private-dns-record-a/main.bicep' = {
  scope: rg_dns
  name: 'dns-a-acr-region'
  params: {
    ipAddress: peAcr.outputs.ip_0
    recordName: '${containerRegistry.outputs.acrName}.${location}.data'
    zone: 'privatelink.azurecr.io'
  }
}

module acr_dns_pe_1 '../modules/network/private-dns-record-a/main.bicep' = {
  scope: rg_dns
  name: 'dns-a-acr-root'
  params: {
    ipAddress: peAcr.outputs.ip_1
    recordName: containerRegistry.outputs.acrName
    zone: 'privatelink.azurecr.io'
  }
}

module containerenvironment '../modules/containers/container-environment/main.bicep' = {
  scope: rg_cae
  name: 'eshop-cae-01'
  params: {
    location: location
    environmentName: 'eshop-cae-01'
    snetId: '${vnet.id}/subnets/snet-cae-01'
  }
}

module dnsZone '../modules/network/private-dns-zone/main.bicep' = {
  scope: rg_cae
  name: '${containerenvironment.name}-dns'
  params: {
    resourceTags: resourceTags
    registrationEnabled: false
    zoneName: containerenvironment.outputs.defaultDomain
    vnetName: 'cae'
    vnetId: vnet.id
  }
}

module userMiCAE '../modules/identity/user-managed-identity/main.bicep' = {
  scope: rg_cae
  name: 'eshop-cae-user-mi'
  params: {
    location: location
    miname: 'eshop-cae-user-mi'
  }
}

module acrRole '../modules/identity/role-assignment-rg/main.bicep' = {
  scope: rg_acr
  name: 'eshop-cae-mi-acr-role'
  params: {
    principalId: userMiCAE.outputs.managedIdentityPrincipal
    principalType: 'ServicePrincipal'
    roleName: 'AcrPull'
  }
}
