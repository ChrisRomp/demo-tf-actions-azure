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

# Virtual network and subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.storage_account_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "private-endpoint-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  private_endpoint_network_policies_enabled = true
}

# storage account
resource "azurerm_storage_account" "storage" {
    name                          = var.storage_account_name
    resource_group_name           = data.azurerm_resource_group.rg.name
    location                      = data.azurerm_resource_group.rg.location
    account_tier                  = "Standard"
    account_replication_type      = "LRS"
    https_traffic_only_enabled    = true
    shared_access_key_enabled     = false
    public_network_access_enabled = false
}

# Private endpoint for the storage account
resource "azurerm_private_endpoint" "endpoint" {
  name                = "${var.storage_account_name}-endpoint"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "${var.storage_account_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# Private DNS zone for blob storage
resource "azurerm_private_dns_zone" "private_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Link the private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "${var.storage_account_name}-dnslink"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# DNS A Record for the private endpoint
resource "azurerm_private_dns_a_record" "dns_a" {
  name                = var.storage_account_name
  zone_name           = azurerm_private_dns_zone.private_dns.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.endpoint.private_service_connection[0].private_ip_address]
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
