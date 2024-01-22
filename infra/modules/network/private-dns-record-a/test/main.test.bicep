targetScope = 'subscription'

resource rg_dns 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'rg-dns'
}

module dnsA '../main.bicep' = {
  scope: rg_dns
  name: 'apex'  
  params: {    
    ipAddress: '10.0.0.1'
    recordName: '*'
    zone: 'contoso.com'
  }
}
