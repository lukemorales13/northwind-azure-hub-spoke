variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "app_service_name" { type = string }
variable "app_service_plan_sku" { type = string }
variable "runtime_stack" { type = string }
variable "app_subnet_id" { type = string }
variable "allowed_inbound_ip_ranges" { type = list(string) }
variable "tags" { type = map(string) }
