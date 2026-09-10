output "private_endpoint_ids" {
  value = { for name, endpoint in azurerm_private_endpoint.this : name => endpoint.id }
}

output "private_endpoint_private_ips" {
  value = {
    for name, endpoint in azurerm_private_endpoint.this :
    name => endpoint.network_interface[0].ip_configuration[0].private_ip_address
  }
}
