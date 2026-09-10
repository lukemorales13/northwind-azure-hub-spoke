resource "azurerm_mssql_server" "this" {
  name                          = var.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_mssql_database" "this" {
  name      = var.database_name
  server_id = azurerm_mssql_server.this.id
  sku_name  = "Basic"
  tags      = var.tags
}
