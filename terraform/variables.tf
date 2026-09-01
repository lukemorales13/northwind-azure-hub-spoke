variable "project" {
  type    = string
  default = "northwind"
}

variable "environment" {
  type    = string
  default = "mvp"
  validation {
    condition     = contains(["dev", "staging", "prod", "mvp"], var.environment)
    error_message = "environment debe ser dev, staging, prod o mvp."
  }
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "owner" {
  type    = string
  default = "equipo-cloud-iimas"
}

variable "cost_center" {
  type    = string
  default = "CloudClass"
}

variable "workload" {
  type    = string
  default = "PrivateIntranet"
}

variable "criticality" {
  type    = string
  default = "low"
  validation {
    condition     = contains(["low", "medium", "high", "critical"], var.criticality)
    error_message = "criticality debe ser low, medium, high o critical."
  }
}

variable "allowed_management_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "enable_bastion" {
  type    = bool
  default = false
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "enable_app_service" {
  type    = bool
  default = false
}

variable "enable_sql_database" {
  type    = bool
  default = false
}

variable "enable_storage" {
  type    = bool
  default = false
}

variable "enable_key_vault" {
  type    = bool
  default = false
}

variable "enable_private_endpoints" {
  type    = bool
  default = false
}

variable "enable_monitoring" {
  type    = bool
  default = false
}

variable "app_service_plan_sku" {
  type    = string
  default = "B1"
}

variable "app_allowed_inbound_ip_ranges" {
  type    = list(string)
  default = []
}

variable "create_documents_container" {
  type    = bool
  default = false
}

variable "key_vault_purge_protection_enabled" {
  type    = bool
  default = false
}

variable "log_analytics_sku" {
  type    = string
  default = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  type    = number
  default = 30
}

variable "sql_administrator_login" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_password" {
  description = "Se entrega como TF_VAR_sql_admin_password desde un secret del entorno de CI; nunca en tfvars."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
  validation {
    condition     = !var.enable_sql_database || (var.sql_admin_password != null && length(var.sql_admin_password) >= 16)
    error_message = "Al habilitar SQL, sql_admin_password debe venir de un secret y tener al menos 16 caracteres."
  }
}
