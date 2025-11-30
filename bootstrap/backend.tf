terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "tfstatecar01"      # must match the imported storage account
    container_name        = "tfstate"           # must match the imported container
    key                   = "terraform.tfstate" # the blob name inside the container
  }
}
###