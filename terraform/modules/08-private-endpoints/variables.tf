variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }

variable "private_endpoints" {
  type = map(object({
    subnet_id                      = string
    private_connection_resource_id = string
    subresource_names              = list(string)
    private_dns_zone_ids           = list(string)
  }))
}
