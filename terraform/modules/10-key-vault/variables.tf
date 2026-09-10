variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "key_vault_name" { type = string }
variable "tenant_id" { type = string }
variable "purge_protection_enabled" { type = bool }
variable "soft_delete_retention_days" { type = number }
variable "tags" { type = map(string) }
