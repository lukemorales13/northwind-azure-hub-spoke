data "azurerm_subnet" "gateway_subnet" {
  name                 = var.gateway_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_public_ip" "gateway_pip" {
  name                = "pip-${var.virtual_network_name}-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "vpngw-${var.virtual_network_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku = "VpnGw1"

  ip_configuration {
    name                 = "vpngw-ipcfg"
    public_ip_address_id = azurerm_public_ip.gateway_pip.id
    subnet_id            = data.azurerm_subnet.gateway_subnet.id
  }

  tags = var.tags
}

