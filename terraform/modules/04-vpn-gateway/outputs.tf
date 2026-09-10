output "gateway_id" {
  description = "ID of the Virtual Network Gateway"
  value       = azurerm_virtual_network_gateway.this.id
}

output "gateway_public_ip" {
  description = "Public IP address allocated for the gateway"
  value       = azurerm_public_ip.gateway_pip.ip_address
}

