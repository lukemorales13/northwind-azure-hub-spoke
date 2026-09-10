variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_ids" { type = map(string) }
variable "app_subnet_name" { type = string }
variable "data_subnet_name" { type = string }
variable "private_endpoint_subnet_name" { type = string }
variable "allowed_management_cidr_blocks" { type = list(string) }
variable "tags" { type = map(string) }
