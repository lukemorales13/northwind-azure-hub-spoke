# Module `07-storage`

Creates a storage account and a `documents` blob container used by the RAG pipeline. Defaults are permissive for dev; tighten `network_rules` once private endpoints are in place.

Inputs:
- `resource_group_name`, `location`, `storage_account_name`, `sku`, `tags`

Outputs:
- `storage_account_id`, `storage_account_name`, `blob_endpoint`
