# Module `05-app-service`

Creates an App Service Plan and App Service. Optionally wires Regional VNet Integration when `app_subnet_id` is provided.

Inputs:
- `resource_group_name`, `location`, `app_service_name`, `app_service_plan_sku`, `is_linux`, `runtime_stack`, `app_subnet_id`, `tags`

Outputs:
- `app_service_id`, `app_service_default_site_hostname`

