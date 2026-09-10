output "bastion_host_id" {
  description = "ID of the Azure Bastion Host"
  value       = azurerm_bastion_host.this.id
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion Host"
  value       = azurerm_bastion_host.this.name
}

output "bastion_public_ip" {
  description = "Public IP address allocated for Bastion"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

