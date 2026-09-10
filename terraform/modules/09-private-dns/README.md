# Module `09-private-dns`

Creates a Private DNS zone and links it to one or more VNets. Used to resolve private endpoint IPs for services such as Storage (blob).

Inputs:
- `resource_group_name`, `location`, `zone_name`, `vnet_ids`, `tags`

Outputs:
- `private_dns_zone_id`, `private_dns_zone_name`
