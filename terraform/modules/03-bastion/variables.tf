variable "resource_group_name" {
  description = "Resource Group name where Bastion will be deployed"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "virtual_network_name" {
  description = "Hub virtual network name that contains the AzureBastionSubnet"
  type        = string
}

variable "bastion_subnet_name" {
  description = "Name of the subnet reserved for Azure Bastion (AzureBastionSubnet)"
  type        = string
  default     = "AzureBastionSubnet"
}

variable "tags" {
  description = "Tags map to apply to created resources"
  type        = map(string)
  default     = {}
}

