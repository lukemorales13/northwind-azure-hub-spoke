data "azurerm_subnet" "bastion_subnet" {
  name                 = var.bastion_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-${var.virtual_network_name}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bastion-${var.virtual_network_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "bastion-ip-config"
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
    subnet_id            = data.azurerm_subnet.bastion_subnet.id
  }

  depends_on = [azurerm_public_ip.bastion_pip]
  tags       = var.tags
}

