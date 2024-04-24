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

# terraform init
# terraform plan -out main.tfplan -var "resource_group_name=$AZURE_RESOURCE_GROUP" -var "storage_account_name=$AZURE_STORAGE_ACCOUNT_NAME"
# terraform apply main.tfplan
