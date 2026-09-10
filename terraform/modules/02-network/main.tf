locals {
  subnet_nsgs = {
    (var.app_subnet_name)              = "nsg-${var.app_subnet_name}"
    (var.data_subnet_name)             = "nsg-${var.data_subnet_name}"
    (var.private_endpoint_subnet_name) = "nsg-${var.private_endpoint_subnet_name}"
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnet_nsgs

  name                = each.value
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Azure defaults permit all VirtualNetwork traffic. This explicit rule blocks
# direct Internet ingress while preserving private east-west connectivity.
resource "azurerm_network_security_rule" "deny_internet_inbound" {
  for_each = azurerm_network_security_group.this

  name                        = "Deny-Internet-Inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = each.value.name
}

# Empty by default: populate only known corporate CIDRs if an HTTPS management
# path is genuinely needed by a future workload in the app subnet.
resource "azurerm_network_security_rule" "allow_management_https" {
  for_each = toset(var.allowed_management_cidr_blocks)

  name                        = "Allow-Management-HTTPS-${replace(each.value, "/", "-")}"
  priority                    = 200 + index(var.allowed_management_cidr_blocks, each.value)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = each.value
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[var.app_subnet_name].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnet_nsgs

  subnet_id                 = var.subnet_ids[each.key]
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
