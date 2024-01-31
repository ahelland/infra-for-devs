using './main.bicep'

param resourceTags = {            
  IaC: 'Bicep'
  Source: 'GitHub'
}
        
param location = 'westeurope'

// Conditionals for granular deployment of individual services
// Note: You may see deployment errors when not enabling services,
// but it should still go through for the ones set to 'true'.
param deploy_postgres = true
param deploy_rabbitMQ = true
param deploy_redis    = true

param deploy_basketAPI        = true
param deploy_bff              = true
param deploy_catalogAPI       = true
param deploy_identityAPI      = true
param deploy_orderProcessor   = true
param deploy_orderingAPI      = true
param deploy_paymentProcessor = true
param deploy_webApp           = true
param deploy_webhooksAPI      = true
param deploy_webhooksClient   = true
