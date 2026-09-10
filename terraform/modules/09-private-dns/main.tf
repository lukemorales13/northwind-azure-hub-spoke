locals {
  vnet_zone_links = {
    for pair in setproduct(keys(var.zones), var.vnet_ids) :
    "${pair[0]}-${substr(md5(pair[1]), 0, 10)}" => {
      zone_key = pair[0]
      vnet_id  = pair[1]
    }
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each = var.zones

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.vnet_zone_links

  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone_key].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false
}
