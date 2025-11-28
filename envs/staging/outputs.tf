output "web_vm_private_ip" {
  value = azurerm_network_interface.web_nic.private_ip_address
}

output "app_vm_private_ip" {
  value = azurerm_network_interface.app_nic.private_ip_address
}

output "web_vm_id" {
  value = azurerm_linux_virtual_machine.web_vm.id
}

output "app_vm_id" {
  value = azurerm_linux_virtual_machine.app_vm.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_workspace.id
}