variable "resource_group_name" {
    type = string
    description = "The name of the resource group in which the resources will be managed."
}

variable "storage_account_name" {
    type = string
    description = "The name of the storage account."
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.100.0"
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
    storage_use_azuread = true
    features {}
}

data "azurerm_resource_group" "rg" {
    name = var.resource_group_name
}

# storage account
resource "azurerm_storage_account" "storage" {
    name                          = var.storage_account_name
    resource_group_name           = data.azurerm_resource_group.rg.name
    location                      = data.azurerm_resource_group.rg.location
    account_tier                  = "Standard"
    account_replication_type      = "LRS"
    enable_https_traffic_only     = true
    shared_access_key_enabled     = false
    # public_network_access_enabled = false
}

# STATE_RESOURCE_GROUP=xxxx
# STATE_STORAGE_ACCOUNT_NAME=xxxx
# STATE_CONTAINER_NAME=tfstate
# STATE_KEY_NAME=terraform.tfstate
# DEPLOY_RESOURCE_GROUP=xxxx
# DEPLOY_STORAGE_ACCOUNT_NAME=xxxx
# terraform init -backend-config="resource_group_name=$STATE_RESOURCE_GROUP" -backend-config="storage_account_name=$STATE_STORAGE_ACCOUNT_NAME" -backend-config="container_name=$STATE_CONTAINER_NAME" -backend-config="key=$STATE_KEY_NAME"
# terraform plan -out main.tfplan -var "resource_group_name=$DEPLOY_RESOURCE_GROUP" -var "storage_account_name=$DEPLOY_STORAGE_ACCOUNT_NAME"
# terraform apply main.tfplan
