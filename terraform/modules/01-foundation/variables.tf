/*
  Se definen los tipos de datos y sus nombres 
*/

variable "resource_group_name" {
  description = "Nombre del Resource Group."
  type        = string
}

variable "location" {
  description = "Region Azure."
  type        = string
}

variable "hub_vnet_name" {
  description = "Nombre de la Hub VNet."
  type        = string
}

variable "hub_address_space" {
  description = "CIDR de la Hub VNet."
  type        = list(string)
}

variable "spoke_vnet_name" {
  description = "Nombre de la Spoke VNet de Operaciones."
  type        = string
}

variable "spoke_address_space" {
  description = "CIDR de la Spoke VNet de Operaciones."
  type        = list(string)
}

variable "sales_vnet_name" {
  description = "Nombre de la Spoke VNet de Ventas."
  type        = string
}

variable "sales_address_space" {
  description = "CIDR de la Spoke VNet de Ventas."
  type        = list(string)
}

variable "hub_subnets" {
  description = "Mapa nombre -> CIDR para subnets del Hub."
  type        = map(string)
}

variable "spoke_subnets" {
  description = "Mapa nombre -> CIDR para subnets del Spoke Operaciones."
  type        = map(string)
}

variable "sales_subnets" {
  description = "Mapa nombre -> CIDR para subnets del Spoke Ventas."
  type        = map(string)
}

variable "app_subnet_name" {
  description = "Nombre de la subnet de aplicacion que se delega para App Service."
  type        = string
  default     = "snet-app-ops"
}

variable "sales_app_subnet_name" {
  description = "Nombre de la subnet de Ventas que se delega para App Service."
  type        = string
  default     = "snet-app-ventas"
}

variable "private_endpoint_subnet_name" {
  description = "Nombre de la subnet que aloja private endpoints."
  type        = string
  default     = "snet-private-endpoints-ops"
}

variable "hub_to_spoke_peer" {
  description = "Nombre del peering Hub -> Spoke."
  type        = string
}

variable "spoke_to_hub_peer" {
  description = "Nombre del peering Spoke -> Hub."
  type        = string
}

variable "hub_to_sales_peer" {
  description = "Nombre del peering Hub -> Spoke Ventas."
  type        = string
}

variable "sales_to_hub_peer" {
  description = "Nombre del peering Spoke Ventas -> Hub."
  type        = string
}

variable "tags" {
  description = "Tags comunes para los recursos."
  type        = map(string)
}
