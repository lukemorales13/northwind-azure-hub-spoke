resource "azurerm_service_plan" "this" {
  name                = "plan-${var.app_service_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                     = var.app_service_plan_sku == "B1" ? false : true
    ftps_state                    = "Disabled"
    http2_enabled                 = true
    minimum_tls_version           = "1.2"
    ip_restriction_default_action = length(var.allowed_inbound_ip_ranges) > 0 ? "Deny" : "Allow"

    application_stack {
      python_version = var.runtime_stack
    }

    dynamic "ip_restriction" {
      for_each = toset(var.allowed_inbound_ip_ranges)
      content {
        name       = "Allow-${replace(ip_restriction.value, "/", "-")}"
        priority   = 100 + index(var.allowed_inbound_ip_ranges, ip_restriction.value)
        action     = "Allow"
        ip_address = ip_restriction.value
      }
    }
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  tags = var.tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  count = var.app_subnet_id != "" ? 1 : 0

  app_service_id = azurerm_linux_web_app.this.id
  subnet_id      = var.app_subnet_id
}
