@description('Environment name used to build resource names')
param environmentName string = 'test'

output resourceGroupNameHint string = 'rg-${environmentName}'
