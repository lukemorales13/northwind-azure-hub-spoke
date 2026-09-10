variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sql_server_name" { type = string }
variable "administrator_login" { type = string }
variable "administrator_password" { type = string }
variable "database_name" { type = string }
variable "tags" { type = map(string) }
