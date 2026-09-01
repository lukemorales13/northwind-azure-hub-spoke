module "foundation" {
  source = "./modules/01-foundation"

  location            = var.location
  resource_group_name = local.names.resource_group

  hub_vnet_name     = local.names.hub_vnet
  hub_address_space = ["10.0.0.0/16"]
  hub_to_spoke_peer = local.names.hub_to_ops_peer

  spoke_vnet_name     = local.names.spoke_ops_vnet
  spoke_address_space = ["10.1.0.0/16"]
  spoke_to_hub_peer   = local.names.ops_to_hub_peer

  sales_vnet_name     = local.names.spoke_sales_vnet
  sales_address_space = ["10.2.0.0/16"]
  hub_to_sales_peer   = local.names.hub_to_sales_peer
  sales_to_hub_peer   = local.names.sales_to_hub_peer

  hub_subnets = {
    snet-management    = "10.0.0.0/24"
    GatewaySubnet      = "10.0.1.0/27"
    AzureBastionSubnet = "10.0.2.0/26"
  }

  spoke_subnets = {
    snet-app-ops               = "10.1.1.0/24"
    snet-data-ops              = "10.1.2.0/24"
    snet-private-endpoints-ops = "10.1.3.0/24"
  }

  sales_subnets = {
    snet-app-ventas               = "10.2.1.0/24"
    snet-data-ventas              = "10.2.2.0/24"
    snet-private-endpoints-ventas = "10.2.3.0/24"
  }

  app_subnet_name              = "snet-app-ops"
  sales_app_subnet_name        = "snet-app-ventas"
  private_endpoint_subnet_name = "snet-private-endpoints-ops"
  tags                         = local.common_tags
}

module "network" {
  source = "./modules/02-network"

  resource_group_name            = module.foundation.resource_group_name
  location                       = var.location
  subnet_ids                     = module.foundation.spoke_subnet_ids
  app_subnet_name                = "snet-app-ops"
  data_subnet_name               = "snet-data-ops"
  private_endpoint_subnet_name   = "snet-private-endpoints-ops"
  allowed_management_cidr_blocks = var.allowed_management_cidr_blocks
  tags                           = local.common_tags
}

# Costly services are opt-in. Enable one capability at a time after reviewing a
# saved plan and the cost estimate; see docs/11-deployment-and-hardening.md.
module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "./modules/03-bastion"

  resource_group_name  = module.foundation.resource_group_name
  location             = var.location
  virtual_network_name = module.foundation.hub_vnet_name
  bastion_subnet_name  = "AzureBastionSubnet"
  tags                 = local.common_tags
}

module "vpn_gateway" {
  count  = var.enable_vpn_gateway ? 1 : 0
  source = "./modules/04-vpn-gateway"

  resource_group_name  = module.foundation.resource_group_name
  location             = var.location
  virtual_network_name = module.foundation.hub_vnet_name
  gateway_subnet_name  = "GatewaySubnet"
  tags                 = local.common_tags
}

module "app_service" {
  count  = var.enable_app_service ? 1 : 0
  source = "./modules/05-app-service"

  resource_group_name       = module.foundation.resource_group_name
  location                  = var.location
  app_service_name          = "app-${local.name_suffix}"
  app_service_plan_sku      = var.app_service_plan_sku
  runtime_stack             = "3.11"
  app_subnet_id             = module.foundation.spoke_subnet_ids["snet-app-ops"]
  allowed_inbound_ip_ranges = var.app_allowed_inbound_ip_ranges
  tags                      = local.common_tags
}

module "sql_database" {
  count  = var.enable_sql_database ? 1 : 0
  source = "./modules/06-sql-database"

  resource_group_name    = module.foundation.resource_group_name
  location               = var.location
  sql_server_name        = "sql-${local.compact_name_suffix}"
  administrator_login    = var.sql_administrator_login
  administrator_password = var.sql_admin_password
  database_name          = "db-northwind-${local.name_suffix}"
  tags                   = local.common_tags
}

module "storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./modules/07-storage"

  resource_group_name        = module.foundation.resource_group_name
  location                   = var.location
  storage_account_name       = "st${local.storage_name_suffix}"
  create_documents_container = var.create_documents_container
  tags                       = local.common_tags
}

module "key_vault" {
  count  = var.enable_key_vault ? 1 : 0
  source = "./modules/10-key-vault"

  resource_group_name        = module.foundation.resource_group_name
  location                   = var.location
  key_vault_name             = "kv-${local.compact_name_suffix}"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = var.key_vault_purge_protection_enabled
  soft_delete_retention_days = 7
  tags                       = local.common_tags
}

module "private_dns" {
  count  = var.enable_private_endpoints ? 1 : 0
  source = "./modules/09-private-dns"

  resource_group_name = module.foundation.resource_group_name
  zones               = local.private_dns_zones
  vnet_ids            = [module.foundation.hub_vnet_id, module.foundation.spoke_vnet_id, module.foundation.sales_vnet_id]
  tags                = local.common_tags
}

module "private_endpoints" {
  count  = var.enable_private_endpoints ? 1 : 0
  source = "./modules/08-private-endpoints"

  resource_group_name = module.foundation.resource_group_name
  location            = var.location
  private_endpoints   = local.private_endpoints
  tags                = local.common_tags
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/11-monitoring"

  resource_group_name       = module.foundation.resource_group_name
  location                  = var.location
  log_analytics_name        = "law-${local.name_suffix}"
  application_insights_name = "appi-${local.name_suffix}"
  workspace_sku             = var.log_analytics_sku
  retention_in_days         = var.log_analytics_retention_in_days
  tags                      = local.common_tags
}
