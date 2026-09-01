resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = "pe-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "psc-${each.key}"
    private_connection_resource_id = each.value.private_connection_resource_id
    is_manual_connection           = false
    subresource_names              = each.value.subresource_names
  }

  tags = var.tags
}

# Note: private_dns_zone_group configuration is handled separately via a data-plane operation
# or azurerm_private_endpoint_private_dns_zone_group resource (requires investigation for AzureRM 4.72 compatibility)
