# Module `06-sql-database`

Creates an Azure SQL Server and an initial database. **Important:** provide `administrator_password` securely (e.g., from environment, secret manager, or Key Vault). This module keeps defaults minimal (Basic DB) for dev/testing.

Inputs:
- `resource_group_name`, `location`, `sql_server_name`, `administrator_login`, `administrator_password`, `database_name`, `tags`

Outputs:
- `sql_server_fqdn`, `database_id`

