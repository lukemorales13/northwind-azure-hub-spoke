variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "log_analytics_name" { type = string }
variable "application_insights_name" { type = string }
variable "workspace_sku" { type = string }
variable "retention_in_days" { type = number }
variable "tags" { type = map(string) }
