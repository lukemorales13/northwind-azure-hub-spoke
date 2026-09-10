output "private_dns_zone_ids" {
  value = { for name, zone in azurerm_private_dns_zone.this : name => zone.id }
}

output "private_dns_zone_names" {
  value = { for name, zone in azurerm_private_dns_zone.this : name => zone.name }
}
