output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}
