# Terraform Backend Bootstrap

## Overview

The remote Terraform state backend must be created **before** any CI/CD workflow can run. This is a one-time bootstrap process that creates a dedicated storage account for Terraform state with security best practices:

- No public access
- RBAC only (no access keys in CI)
- Blob versioning enabled (state history)
- Soft delete enabled (recovery from accidental deletes)
- TLS 1.2 required
- Entra ID authentication

## Prerequisites

- Azure CLI installed and authenticated: `az login --use-device-code`
- Subscription ID known
- Permissions to create resource groups and storage accounts
- A unique suffix (e.g., your initials + timestamp) for naming

## Manual Bootstrap with Azure CLI

```bash
# Set variables
SUBSCRIPTION_ID="your-subscription-id"
UNIQUE_SUFFIX="tfstate001"  # e.g., lm20250901
LOCATION="eastus"

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"

# 1. Create resource group for state
RG_NAME="rg-tfstate-${UNIQUE_SUFFIX}"
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  --tags \
    Purpose="TerraformState" \
    ManagedBy="Manual" \
    Created="$(date +%Y-%m-%d)"

# 2. Create storage account
STORAGE_ACCOUNT_NAME="sttfstate${UNIQUE_SUFFIX}"
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku "Standard_LRS" \
  --kind "StorageV2" \
  --access-tier "Hot" \
  --https-only true \
  --min-tls-version "TLS1_2" \
  --public-network-access "Enabled" \
  --tags \
    Purpose="TerraformState" \
    ManagedBy="Manual"

# 3. Disable storage account access keys (RBAC only)
az storage account update \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RG_NAME" \
  --default-action "Deny" \
  --bypass "AzureServices"

# 4. Create container for state
CONTAINER_NAME="tfstate"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode "login"

# 5. Enable blob versioning and soft delete
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RG_NAME" \
  --enable-versioning true \
  --enable-soft-delete true \
  --soft-delete-days 30

# 6. Output values for terraform init
echo "=== Backend Configuration ==="
echo "Resource Group: $RG_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo ""
echo "Use these values in GitHub Environment variables:"
echo "TFSTATE_RESOURCE_GROUP=$RG_NAME"
echo "TFSTATE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT_NAME"
echo "TFSTATE_CONTAINER=$CONTAINER_NAME"
```

## Terraform-based Bootstrap (Alternative)

Create `terraform/bootstrap/main.tf` to manage the state backend infrastructure itself:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "subscription_id" {
  type = string
}

variable "unique_suffix" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate-${var.unique_suffix}"
  location = var.location

  tags = {
    Purpose   = "TerraformState"
    ManagedBy = "Terraform"
    CreatedAt = timestamp()
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${var.unique_suffix}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  https_only               = true
  min_tls_version          = "TLS1_2"
  public_network_access_enabled = false

  tags = azurerm_resource_group.tfstate.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_account_blob_properties" "tfstate" {
  storage_account_id = azurerm_storage_account.tfstate.id

  versioning_enabled       = true
  delete_retention_policy {
    days = 30
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}
```

Run from `terraform/bootstrap` directory:
```bash
terraform init
terraform plan -var="subscription_id=$SUBSCRIPTION_ID" -var="unique_suffix=$UNIQUE_SUFFIX"
terraform apply -var="subscription_id=$SUBSCRIPTION_ID" -var="unique_suffix=$UNIQUE_SUFFIX"
```

## RBAC Configuration for CI/CD

After creating the backend, configure OIDC identity with least-privilege access:

```bash
# Create Azure AD app registration (if not already existing)
APP_NAME="northwind-terraform-oidc"
APP=$(az ad app create --display-name "$APP_NAME")
APP_ID=$(echo $APP | jq -r '.appId')
OBJECT_ID=$(echo $APP | jq -r '.id')

# Create service principal
az ad sp create --id "$APP_ID"

# Create federated credential for GitHub
REPO_OWNER="your-github-username"
REPO_NAME="northwind-azure-hub-spoke"
GITHUB_ENTITY_ID="repo:${REPO_OWNER}/${REPO_NAME}:environment:mvp"

az ad app federated-credential create \
  --id "$OBJECT_ID" \
  --parameters '{
    "name": "github-mvp",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "'$GITHUB_ENTITY_ID'",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Grant Contributor on workload RG (not Owner)
WORKLOAD_RG="rg-northwind-mvp"
az role assignment create \
  --assignee-object-id "$OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$WORKLOAD_RG"

# Grant Storage Blob Data Contributor on state container only
STORAGE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
az role assignment create \
  --assignee-object-id "$OBJECT_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ID/blobServices/default/containers/$CONTAINER_NAME"

echo "AZURE_CLIENT_ID=$APP_ID"
echo "AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)"
```

## GitHub Environment Configuration

In the repository settings, create `mvp` and `prod-reference` environments with:

**Secrets:**
- `SQL_ADMIN_PASSWORD` (if using SQL; must be 16+ chars)

**Variables (not secrets):**
- `AZURE_CLIENT_ID` (from OIDC app)
- `AZURE_TENANT_ID` (subscription tenant)
- `AZURE_SUBSCRIPTION_ID` (target subscription)
- `TFSTATE_RESOURCE_GROUP` (e.g., `rg-tfstate-tfstate001`)
- `TFSTATE_STORAGE_ACCOUNT` (e.g., `sttfstatetfstate001`)
- `TFSTATE_CONTAINER` (`tfstate`)

**Protection rules (mvp environment):**
- Required reviewers: 1
- Allow deployments from: selected branches (main only)

**Protection rules (prod-reference environment):**
- Required reviewers: 2 (strict approval)
- Allow deployments from: selected branches (main only)

## Verify Backend Access

```bash
# Initialize backend locally to verify it works
cd terraform
terraform init -reconfigure \
  -backend-config="resource_group_name=$RG_NAME" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
  -backend-config="container_name=$CONTAINER_NAME" \
  -backend-config="key=northwind/mvp.tfstate" \
  -backend-config="use_azuread_auth=true"

# This will create an empty tfstate in the backend
```

## Security Notes

1. **Access Keys**: Never store storage account access keys in GitHub. RBAC is the only supported method.
2. **State Isolation**: Use separate keys (paths) for different environments: `northwind/mvp.tfstate`, `northwind/prod.tfstate`.
3. **Purge Protection**: Consider enabling purge protection on the storage account after MVP is stable (it cannot be disabled later).
4. **Audit Logging**: Enable diagnostic settings on the storage account to log all data-plane operations to Log Analytics.
5. **OIDC Only**: Do not create personal access tokens or use `az login` secrets in CI. OIDC is the secure, credential-free approach.

## Cost Impact

- Storage Account (Standard LRS): ~$1-2/month
- Blob transactions: negligible for Terraform state
- Data transfer: free within Azure (no egress charges for CI runs)

**Total**: ~$2/month for the backend infrastructure.

## Cleanup

To remove the backend (careful—this deletes state history):

```bash
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait
```

## Next Steps

After bootstrap:
1. Configure GitHub Environments and budget alerts
2. Run first `terraform plan` from CI/CD workflow (manual dispatch)
3. Review saved plan, then `terraform apply`
4. Enable services incrementally (foundation → network → storage → app service)
