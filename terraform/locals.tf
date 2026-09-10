locals {
  normalized_location = lower(replace(var.location, " ", ""))
  name_suffix         = "${lower(var.project)}-${lower(var.environment)}-${local.normalized_location}"
  compact_name_suffix = replace(local.name_suffix, "-", "")
  storage_name_suffix = substr(replace(local.name_suffix, "-", ""), 0, 20)
  project_tag         = "${lower(var.project)}-${lower(var.environment)}"

  names = {
    resource_group    = "rg-${local.name_suffix}"
    hub_vnet          = "vnet-hub-${local.name_suffix}"
    spoke_ops_vnet    = "vnet-spk-ops-${local.name_suffix}"
    spoke_sales_vnet  = "vnet-spk-ventas-${local.name_suffix}"
    hub_to_ops_peer   = "peer-hub-to-ops-${lower(var.environment)}"
    ops_to_hub_peer   = "peer-ops-to-hub-${lower(var.environment)}"
    hub_to_sales_peer = "peer-hub-to-ventas-${lower(var.environment)}"
    sales_to_hub_peer = "peer-ventas-to-hub-${lower(var.environment)}"
  }

  private_dns_zones = merge(
    var.enable_storage ? { blob = "privatelink.blob.core.windows.net" } : {},
    var.enable_sql_database ? { sql = "privatelink.database.windows.net" } : {},
    var.enable_key_vault ? { keyvault = "privatelink.vaultcore.azure.net" } : {}
  )

  private_endpoints = var.enable_private_endpoints ? merge(
    var.enable_storage ? {
      storage_blob = {
        subnet_id                      = module.foundation.spoke_subnet_ids["snet-private-endpoints-ops"]
        private_connection_resource_id = module.storage[0].storage_account_id
        subresource_names              = ["blob"]
        private_dns_zone_ids           = [module.private_dns[0].private_dns_zone_ids["blob"]]
      }
    } : {},
    var.enable_sql_database ? {
      sql_server = {
        subnet_id                      = module.foundation.spoke_subnet_ids["snet-private-endpoints-ops"]
        private_connection_resource_id = module.sql_database[0].sql_server_id
        subresource_names              = ["sqlServer"]
        private_dns_zone_ids           = [module.private_dns[0].private_dns_zone_ids["sql"]]
      }
    } : {},
    var.enable_key_vault ? {
      key_vault = {
        subnet_id                      = module.foundation.spoke_subnet_ids["snet-private-endpoints-ops"]
        private_connection_resource_id = module.key_vault[0].key_vault_id
        subresource_names              = ["vault"]
        private_dns_zone_ids           = [module.private_dns[0].private_dns_zone_ids["keyvault"]]
      }
    } : {}
  ) : {}

  common_tags = {
    Project     = local.project_tag
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Criticality = var.criticality
    Workload    = var.workload
    ManagedBy   = "Terraform"
  }
}
