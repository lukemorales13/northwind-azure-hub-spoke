output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.this.id
}

output "app_service_default_site_hostname" {
  description = "Default site hostname"
  value       = azurerm_linux_web_app.this.default_hostname
}

