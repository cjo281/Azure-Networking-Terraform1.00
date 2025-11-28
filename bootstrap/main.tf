provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tfstate_rg" {
  name     = "tfstate-rg"
  location = var.location
}

resource "azurerm_storage_account" "tfstate_sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate_container" {
  name                  = var.container_name
  storage_account_id  = azurerm_storage_account.tfstate_sa.id
  container_access_type = "private"
}