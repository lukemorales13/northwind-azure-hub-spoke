variable "resource_group_name" {
  description = "Resource Group name where VPN Gateway will be deployed"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "virtual_network_name" {
  description = "Hub virtual network name that contains the GatewaySubnet"
  type        = string
}

variable "gateway_subnet_name" {
  description = "Name of the subnet reserved for VPN Gateway (GatewaySubnet)"
  type        = string
  default     = "GatewaySubnet"
}

variable "tags" {
  description = "Tags map to apply to created resources"
  type        = map(string)
  default     = {}
}

