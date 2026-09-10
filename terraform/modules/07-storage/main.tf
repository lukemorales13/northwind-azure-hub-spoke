resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  tags                            = var.tags
}

# Creating a container through Terraform is optional because a private-only
# account needs the runner to resolve and reach its private endpoint.
resource "azurerm_storage_container" "documents" {
  count = var.create_documents_container ? 1 : 0

  name                  = "documents"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
