# Deployment and hardening checklist

## Safe sequence for the $200 Azure credit

1. Create a separate `rg-tfstate-*` and a standard LRS state account manually. Enable blob versioning, soft delete, HTTPS only and Entra ID/RBAC access; do not store an access key in GitHub.
2. Create a GitHub OIDC app registration/federated credential. Grant it `Contributor` only on the workload resource group and `Storage Blob Data Contributor` only on the state container. Put the IDs and state names in GitHub Environment variables, not secrets.
3. Run the Terraform workflow with `plan` for `mvp`; inspect the saved plan. The default deployment creates only the resource group, three VNets, peerings, subnets and NSGs. It does not create billable gateway, Bastion, PaaS or monitoring resources.
4. Enable Storage + Key Vault + Private Endpoints as one reviewed change. Test DNS from the App Service integration subnet before disabling any remaining public paths. A private-only Storage account cannot have a container created from a public runner; create it from a private runner or let the application bootstrap it with RBAC.
5. Enable the App Service (B1 for the demo) only with `app_allowed_inbound_ip_ranges` populated. Enable SQL only after setting `SQL_ADMIN_PASSWORD` as a protected GitHub Environment secret. Enable Bastion and VPN only for a short, scheduled demonstration, then destroy them.

## Controls implemented in Terraform

- Workload services have explicit `enable_*` flags, all defaulting to `false`.
- NSGs are associated to app, data and private-endpoint subnets and deny direct Internet ingress.
- Storage is private-only, HTTPS/TLS 1.2, OAuth-default, no shared keys and no anonymous blob access.
- Azure SQL disables public network access and enforces TLS 1.2. The SQL password is sensitive and never has a tfvars default.
- Key Vault uses RBAC, soft-delete and no public network access. Turn on purge protection for a non-disposable production vault; it cannot be disabled later.
- Private Endpoints are generic for Blob, SQL and Key Vault and are paired with the correct private DNS zones linked to all VNets.
- App Service uses Linux, managed identity, TLS 1.2, HTTPS-only, disabled FTP and VNet integration.

## Before a real apply

- Configure a budget alert at USD 25 and USD 75, plus an Azure Cost Management anomaly alert. Check the Azure Pricing Calculator for the chosen region/SKU.
- Protect the GitHub `mvp` environment (one required reviewer) and `prod-reference` environment (two reviewers). Only the workflow-dispatch `apply` job should be allowed to use them.
- Create separate OIDC identities for plan and apply if the repository becomes shared; the plan identity can be `Reader` plus state read, while apply keeps scoped `Contributor`.
- Use Azure RBAC groups, least privilege and PIM for human administration. Do not use Owner for CI.
- Add Microsoft Defender for Cloud and Azure Policy (allowed locations, required tags, no public Storage/SQL/Key Vault) before production. These may add cost, so enable them after the MVP evidence is captured.
- Route all production egress through Azure Firewall/NAT Gateway and add diagnostic settings to a Log Analytics workspace. They are intentionally deferred because they consume the free credit quickly.

## CI/CD contract

`terraform.yml` validates format and configuration on every Terraform PR. It does not authenticate to Azure on PRs. A manual dispatch logs in through GitHub OIDC, plans into the encrypted remote state backend, and applies only when the selected GitHub Environment grants approval. Required environment variables: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, and `TFSTATE_CONTAINER`. The only required secret for SQL is `SQL_ADMIN_PASSWORD`.
