provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "network_rg" {
  name     = "NetRG1"
  location = var.location
}
# VNET AND SUBNETS
resource "azurerm_virtual_network" "vnet" {
  name                = "MyVnet1.0"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "WebSubnet1.0"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  #network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "AppSubnet1.0"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  #network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# NSGS
resource "azurerm_network_security_group" "web_nsg" {
  name                = "WebNSG1.0"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.4"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.4"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.4"
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "AppNSG1.0"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.2.4"
  }

  security_rule {
    name                       = "AllowWebSubnet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.4"
  }

  security_rule {
    name                       = "DenyInternetIn"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.2.4"
  }
}


# NSG ASSOCIATIONS
resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# NICS
resource "azurerm_network_interface" "web_nic" {
  name                = "WebVM1.0Nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
  }
}

resource "azurerm_network_interface" "app_nic" {
  name                = "AppVM1.0Nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
  }
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "WebVM1.0"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  size                = "Standard_B1ms"
  admin_username      = var.admin_username

  #Because you’re using SSH keys (admin_ssh_key), you don’t need a password.
  #admin_password      = var.admin_password  

  #If you leave this out and don’t provide a password, Terraform will fail. If you set it to false, you must provide admin_password.
  #disable password login for the VM: SSH key authentication
  disable_password_authentication = true
  
  admin_ssh_key 
    { 
        username   = var.admin_username 
        public_key = var.admin_ssh_public_key 
    }

  network_interface_ids = [azurerm_network_interface.web_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  tags = {
    environment = "staging" # change to "production" in production/main.tf
  }
  #This adds a tag to every VM (or resource) indicating its environment. Benefits

}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "AppVM1.0"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  #admin_password      = var.admin_password

  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.app_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  tags = {
    environment = "staging" # change to "production" in production/main.tf
  }

}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "MyLogWorkspace32"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}