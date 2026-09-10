/*
  Se crea lo siguiente:
  1. grupo de recursos principal 
  2. redes hub y spoke_ops independientes
  3. Uso de for_each para subnetting
  4. Delegación dinamica
  5. Bloque de conectividad
*/

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.hub_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke_ops" {
  name                = var.spoke_vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.spoke_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke_sales" {
  name                = var.sales_vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.sales_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  for_each = var.hub_subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

resource "azurerm_subnet" "spoke_ops" {
  for_each = var.spoke_subnets

  name                              = each.key
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.spoke_ops.name
  address_prefixes                  = [each.value]
  private_endpoint_network_policies = each.key == var.private_endpoint_subnet_name ? "Disabled" : "Enabled"

  dynamic "delegation" {
    for_each = each.key == var.app_subnet_name ? [1] : []

    content {
      name = "delegation-app-service"

      service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}

resource "azurerm_subnet" "spoke_sales" {
  for_each = var.sales_subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_sales.name
  address_prefixes     = [each.value]

  dynamic "delegation" {
    for_each = each.key == var.sales_app_subnet_name ? [1] : []

    content {
      name = "delegation-app-service"

      service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = var.hub_to_spoke_peer
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_ops.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_sales" {
  name                      = var.hub_to_sales_peer
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_sales.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "sales_to_hub" {
  name                      = var.sales_to_hub_peer
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.spoke_sales.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = var.spoke_to_hub_peer
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.spoke_ops.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
