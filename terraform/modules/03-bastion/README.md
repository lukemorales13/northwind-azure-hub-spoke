# Module `03-bastion`

Creates an Azure Bastion Host in an existing hub virtual network. Expects the hub VNet and the `AzureBastionSubnet` to already exist (created by `01-foundation`).

Inputs:
- `resource_group_name`, `location`, `virtual_network_name`, `bastion_subnet_name`, `tags`

Outputs:
- `bastion_host_id`, `bastion_host_name`, `bastion_public_ip`

