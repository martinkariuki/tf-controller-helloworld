terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.72.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
}

data "azurerm_resource_group" "flux" {
  name     = "argo-1"
}

module "application" {
  source           = "./modules/container-apps"
  resource_group   = data.azurerm_resource_group.flux.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  database_url = module.database.database_url

  azure_application_insights_instrumentation_key = module.application-insights.azure_application_insights_instrumentation_key

  vault_id  = module.key-vault.vault_id
  vault_uri = module.key-vault.vault_uri

  azure_redis_host = module.redis.azure_redis_host

  azure_storage_account_name  = module.storage-blob.azurerm_storage_account_name
  azure_storage_blob_endpoint = module.storage-blob.azurerm_storage_blob_endpoint
}

module "database" {
  source           = "./modules/sql-server"
  resource_group   = data.azurerm_resource_group.flux.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}

module "application-insights" {
  source           = "./modules/application-insights"
  resource_group   = data.azurerm_resource_group.flux.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}

module "key-vault" {
  source           = "./modules/key-vault"
  resource_group   = data.azurerm_resource_group.flux.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  database_username = module.database.database_username
  database_password = module.database.database_password

  redis_password = module.redis.azure_redis_password

  storage_account_key = module.storage-blob.azurerm_storage_account_key
}

module "redis" {
  source           = "./modules/redis"
  resource_group   = data.azurerm_resource_group.flux.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}

module "storage-blob" {
  source           = "./modules/storage-blob"
  resource_group   = data.azurerm_resource_group.flux.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}
