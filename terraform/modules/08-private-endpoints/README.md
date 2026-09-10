# Module `08-private-endpoints`

Creates a Private Endpoint for a Storage account and optionally links it to a Private DNS Zone via a `private_dns_zone_group`.

Inputs:
- `resource_group_name`, `location`, `subnet_id`, `storage_account_id`, `private_dns_zone_id`, `tags`

Outputs:
- `private_endpoint_id`, `private_endpoint_ip`
