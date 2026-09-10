# Module `04-vpn-gateway`

Creates an Azure Virtual Network Gateway in an existing hub VNet. Expects the `GatewaySubnet` to be present (created by `01-foundation`).

Inputs:
- `resource_group_name`, `location`, `virtual_network_name`, `gateway_subnet_name`, `tags`

Outputs:
- `gateway_id`, `gateway_public_ip`

