targetScope = 'subscription'

@description('Location for Container Environment')
param location string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param subId string = subscription().id
param acrName string = 'acr${uniqueString(subId)}'

//Conditionals for granular deployment of individual services
// Note: You may see deployment errors when not enabling services,
// but it should still go through for the ones set to 'true'.
param deploy_postgres bool
param deploy_rabbitMQ bool
param deploy_redis bool

param deploy_basketAPI bool
param deploy_catalogAPI bool
param deploy_identityAPI bool
param deploy_bff bool
param deploy_orderProcessor bool
param deploy_orderingAPI bool
param deploy_paymentProcessor bool
param deploy_webApp bool
param deploy_webhooksAPI bool
param deploy_webhooksClient bool

resource rg_cae 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'rg-eshop-cae'
}

resource containerenvironment 'Microsoft.App/managedEnvironments@2023-05-02-preview' existing = {
  scope: rg_cae
  name: 'eshop-cae-01'
}

/* If you want to deploy Redis as a service instead of an app use this snippet.
module redisService '../modules/containers/container-app-service/main.bicep' = {
  scope: rg_cae
  name: 'eshop-redis'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    serviceName: 'redis'
    serviceType: 'redis'
  }
}
*/

module redisApp '../modules/containers/container-app-docker-hub/main.bicep' = if(deploy_redis) {
  scope: rg_cae
  name: 'eshop-redis'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    name: 'redis'
    containerName: 'redis'
    containerImage: 'redis:latest'
    targetPort: 6379
    transport: 'tcp'
    minReplicas: 1 
  }
}

module rabbitMQApp '../modules/containers/container-app-docker-hub/main.bicep' = if(deploy_rabbitMQ) {
  scope: rg_cae
  name: 'eshop-rabbitmq'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    name: 'eventbus'
    containerImage: 'rabbitmq:3-management'
    containerName: 'eventbus'
    targetPort: 5672
    transport: 'tcp'
    minReplicas: 1
  }
}

// Deploys a PostgreSQL database with vector support
module postgresVectorApp '../modules/containers/container-app-docker-hub/main.bicep' = if(deploy_postgres) {
  scope: rg_cae
  name: 'eshop-postgres'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    name: 'postgres'
    containerImage: 'ankane/pgvector:latest'
    containerName: 'postgres'
    targetPort: 5432
    transport: 'tcp'
    minReplicas: 1
    envVars: [
      { name: 'POSTGRES_HOST_AUTH_METHOD', value: 'scram-sha-256' }
      { name: 'POSTGRES_INITDB_ARGS', value: '--auth-host=scram-sha-256 --auth-local=scram-sha-256' }
      { name: 'POSTGRES_PASSWORD', value: 'foo' }
    ]
  }
}

module basketapi '../modules/containers/container-app-acr/main.bicep' = if(deploy_basketAPI) {
  scope: rg_cae
  name: 'eshop-basketapi'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/basketapi:latest'
    targetPort: 8080
    //The basket api uses gRPC which required http2
    transport: 'http2'
    externalIngress: false
    containerName: 'basket-api'
    identityName: 'eshop-cae-user-mi'
    name: 'basket-api'
    minReplicas: 1
    //If you want to bind to a Redis service uncomment the line below
    //serviceId: redisService.outputs.id
    envVars: [
      { name: 'Identity__Url', value: 'https://identity-api.${containerenvironment.properties.defaultDomain}' }
      { name: 'ConnectionStrings__redis', value: 'redis:6379' }
      { name: 'ConnectionStrings__EventBus', value: 'amqp://guest:guest@eventbus:5672' }
    ]
  }
}

module basketapiDns '../modules/network/private-dns-record-a/main.bicep' =  if(deploy_basketAPI) {
  scope: rg_cae
  name: 'eshop-basketapiDns'
  params: {
    ipAddress: containerenvironment.properties.staticIp
    recordName: basketapi.outputs.name
    zone: containerenvironment.properties.defaultDomain
  }
}

module catalogapi '../modules/containers/container-app-acr/main.bicep' = if(deploy_catalogAPI) {
  scope: rg_cae
  name: 'eshop-catalogapi'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/catalogapi:latest'
    externalIngress: true
    targetPort: 8080
    transport: 'http'
    containerName: 'catalog-api'
    identityName: 'eshop-cae-user-mi'
    name: 'catalog-api'
    minReplicas: 1
    envVars: [
      { name: 'ConnectionStrings__EventBus', value: 'amqp://guest:guest@eventbus:5672' }
      //See: https://learn.microsoft.com/en-us/dotnet/aspire/database/postgresql-entity-framework-component?tabs=dotnet-cli
      { name: 'Aspire__Npgsql__EntityFrameworkCore__PostgreSQL__ConnectionString', value: 'Host=postgres;Database=CatalogDB;Port=5432;Username=postgres;Password=foo' }
    ]
  }
}

module catalogapiDns '../modules/network/private-dns-record-a/main.bicep' = if(deploy_catalogAPI) {
  scope: rg_cae
  name: 'eshop-catalogapiDns'
  params: {
    ipAddress: containerenvironment.properties.staticIp
    recordName: catalogapi.outputs.name
    zone: containerenvironment.properties.defaultDomain
  }
}

module identityapi '../modules/containers/container-app-acr/main.bicep' = if(deploy_identityAPI) {
  scope: rg_cae
  name: 'eshop-identityapi'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/identityapi:latest'
    targetPort: 8080
    transport: 'http'
    containerName: 'identity-api'
    identityName: 'eshop-cae-user-mi'
    name: 'identity-api'
    minReplicas: 1
    envVars: [
      { name: 'ASPNETCORE_ENVIRONMENT',              value: 'Development' }
      { name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED', value: 'true' }
      { name: 'BasketApiClient',   value: 'https://basket-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'OrderingApiClient', value: 'https://ordering-api.${containerenvironment.properties.defaultDomain}' }
      { name: 'WebhooksApiClient', value: 'https://webhooks-api.${containerenvironment.properties.defaultDomain}' }
      { name: 'WebhooksWebClient', value: 'https://webhooksclient.${containerenvironment.properties.defaultDomain}' }
      { name: 'WebAppClient',      value: 'https://webapp.${containerenvironment.properties.defaultDomain}' }  
      { name: 'ConnectionStrings__IdentityDB', value: 'Host=postgres;Database=IdentityDB;Port=5432;Username=postgres;Password=foo' }
    ]
  }
}

module identityapiDns '../modules/network/private-dns-record-a/main.bicep' = if(deploy_identityAPI) {
  scope: rg_cae
  name: 'eshop-identityapiDns'
  params: {
    ipAddress: containerenvironment.properties.staticIp
    recordName: identityapi.outputs.name
    zone: containerenvironment.properties.defaultDomain
  }
}

module orderingapi '../modules/containers/container-app-acr/main.bicep' = if(deploy_orderingAPI) {
  scope: rg_cae
  name: 'eshop-orderingapi'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/orderingapi:latest'
    targetPort: 8080
    transport: 'http'
    containerName: 'ordering-api'
    identityName: 'eshop-cae-user-mi'
    name: 'ordering-api'
    minReplicas: 1
    envVars: [
      { name: 'Identity__Url', value: 'https://identity-api.${containerenvironment.properties.defaultDomain}' }
      { name: 'ConnectionStrings__EventBus', value: 'amqp://guest:guest@eventbus:5672' }
      { name: 'ConnectionStrings__OrderingDB', value: 'Host=postgres;Database=OrderingDB;Port=5432;Username=postgres;Password=foo' }
    ]
  }
}

module orderingapiDns '../modules/network/private-dns-record-a/main.bicep' = if(deploy_orderingAPI) {
  scope: rg_cae
  name: 'eshop-orderingapiDns'
  params: {
    ipAddress: containerenvironment.properties.staticIp
    recordName: orderingapi.outputs.name
    zone: containerenvironment.properties.defaultDomain
  }
}

module mobilebffshopping '../modules/containers/container-app-acr/main.bicep' = if(deploy_bff) {
  scope: rg_cae
  name: 'eshop-mobilebffshopping'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/mobilebffshopping:latest'
    targetPort: 8080
    containerName: 'mobile-bff'
    identityName: 'eshop-cae-user-mi'
    name: 'mobile-bff'
    minReplicas: 1
    envVars: [
      { name: 'services__catalog-api__0',  value: 'catalog-api' }
      { name: 'services__catalog-api__1',  value: 'catalog-api' }
      { name: 'services__identity-api__0', value: 'identity-api' }
      { name: 'services__identity-api__1', value: 'identity-api' }
    ]
  }
}

module orderprocessor '../modules/containers/container-app-acr/main.bicep' = if(deploy_orderProcessor) {
  scope: rg_cae
  name: 'eshop-orderprocessor'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/orderprocessor:latest'
    targetPort: 8080
    transport: 'http'
    containerName: 'order-processor'
    identityName: 'eshop-cae-user-mi'
    name: 'order-processor'
    minReplicas: 1
    envVars: [
      { name: 'ConnectionStrings__EventBus',   value: 'amqp://guest:guest@eventbus:1672' }
      { name: 'ConnectionStrings__OrderingDB', value: 'Host=postgres;Database=OrderingDB;Port=5432;Username=postgres;Password=foo' }
    ]
  }
}

module paymentprocessor '../modules/containers/container-app-acr/main.bicep' = if(deploy_paymentProcessor) {
  scope: rg_cae
  name: 'eshop-paymentprocessor'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/paymentprocessor:latest'
    targetPort: 8080
    transport: 'http'
    externalIngress: false
    containerName: 'payment-processor'
    identityName: 'eshop-cae-user-mi'
    name: 'payment-processor'
    minReplicas: 1
    envVars: [
      { name: 'ConnectionStrings__EventBus', value: 'amqp://guest:guest@eventbus:5672' }
    ]
  }
}

module webhooksapi '../modules/containers/container-app-acr/main.bicep' = if(deploy_webhooksAPI) {
  scope: rg_cae
  name: 'eshop-webhooksapi'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/webhooksapi:latest'
    targetPort: 8080
    transport: 'http'
    externalIngress: false
    containerName: 'webhooks-api'
    identityName: 'eshop-cae-user-mi'
    name: 'webhooks-api'
    minReplicas: 1
    envVars: [
      { name: 'ConnectionStrings__EventBus', value: 'amqp://guest:guest@eventbus:5672' }
      { name: 'ConnectionStrings__WebhooksDB', value: 'Host=postgres;Database=WebhooksDB;Port=5432;Username=postgres;Password=foo' }
      { name: 'Identity__Url', value: 'https://identity-api.${containerenvironment.properties.defaultDomain}' }
    ]
  }
}

// module webhooksapiDns '../modules/network/private-dns-record-a/main.bicep' = if(deploy_webhooksAPI) {
//   scope: rg_cae
//   name: 'eshop-webhooksapiDns'
//   params: {
//     ipAddress: containerenvironment.properties.staticIp
//     recordName: webhooksapi.outputs.name
//     zone: containerenvironment.properties.defaultDomain
//   }
// }

module webhookclient '../modules/containers/container-app-acr/main.bicep' = if(deploy_webhooksClient) {
  scope: rg_cae
  name: 'eshop-webhookclient'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/webhookclient:latest'
    targetPort: 8080
    containerName: 'webhooksclient'
    identityName: 'eshop-cae-user-mi'
    name: 'webhooksclient'
    minReplicas: 1
    envVars: [
      { name: 'IdentityUrl', value: 'https://identity-api.${containerenvironment.properties.defaultDomain}' }
      { name: 'CallBackUrl', value: 'https://webhooksclient.${containerenvironment.properties.defaultDomain}/signin-oidc' }
      { name: 'services__webhooks-api__0', value: 'http://webhooks-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'services__webhooks-api__1', value: 'https://webhooks-api.internal.${containerenvironment.properties.defaultDomain}' }
    ]
  }
}

module webhookclientDns '../modules/network/private-dns-record-a/main.bicep' = if(deploy_webhooksClient) {
  scope: rg_cae
  name: 'eshop-webhookclientDns'
  params: {
    ipAddress: containerenvironment.properties.staticIp
    recordName: webhookclient.outputs.name
    zone: containerenvironment.properties.defaultDomain
  }
}

module webapp '../modules/containers/container-app-acr/main.bicep' = if(deploy_webApp) {
  scope: rg_cae
  name: 'eshop-webapp'
  params: {
    location: location
    resourceTags: resourceTags
    containerAppEnvironmentId: containerenvironment.id
    containerRegistry: '${acrName}.azurecr.io'
    containerImage: '${acrName}.azurecr.io/webapp:latest'
    targetPort: 8080
    transport: 'http'
    containerName: 'webapp'
    identityName: 'eshop-cae-user-mi'
    name: 'webapp'
    minReplicas: 1
    envVars: [
      { name: 'ASPNETCORE_ENVIRONMENT', value: 'Development' }
      { name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED', value: 'true' }
      { name: 'IdentityUrl', value: 'https://identity-api.${containerenvironment.properties.defaultDomain}' }
      { name: 'CallBackUrl', value: 'https://webapp.${containerenvironment.properties.defaultDomain}/signin-oidc' }
      { name: 'ConnectionStrings__EventBus', value: 'amqp://guest:guest@eventbus:5672' }
      { name: 'services__basket-api__0',   value: 'http://basket-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'services__basket-api__1',   value: 'https://basket-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'services__catalog-api__0',  value: 'http://catalog-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'services__catalog-api__1',  value: 'https://catalog-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'services__ordering-api__0', value: 'http://ordering-api.internal.${containerenvironment.properties.defaultDomain}' }
      { name: 'services__ordering-api__1', value: 'https://ordering-api.internal.${containerenvironment.properties.defaultDomain}' }
    ]
  }
}

module webappDns '../modules/network/private-dns-record-a/main.bicep' = if(deploy_webApp) {
  scope: rg_cae
  name: 'eshop-webappDns'
  params: {
    ipAddress: containerenvironment.properties.staticIp
    recordName: webapp.outputs.name
    zone: containerenvironment.properties.defaultDomain
  }
}
