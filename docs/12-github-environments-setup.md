# GitHub Environments Setup for Terraform CI/CD

## Overview

GitHub Environments provide protection rules, approval requirements, and secure secret management for CI/CD. For this project, we use two environments:

1. **mvp** - Development/staging environment (1 required reviewer)
2. **prod-reference** - Reference production environment (2 required reviewers)

## Step 1: Create GitHub Environments

### MVP Environment

1. Go to **Settings** → **Environments** → **New environment**
2. Name: `mvp`
3. Click **Configure environment**

### Prod-Reference Environment

1. Go to **Settings** → **Environments** → **New environment**
2. Name: `prod-reference`
3. Click **Configure environment**

## Step 2: Configure Protection Rules

### MVP Environment Protection

1. In the environment, enable **Deployment branches**
2. Select **Selected branches**
3. Add branch: `main`
4. **Deployment protection rules**:
   - Enable **Required reviewers**: `1 reviewer`
   - Select reviewers (or use the default: repository admin)

### Prod-Reference Environment Protection

1. In the environment, enable **Deployment branches**
2. Select **Selected branches**
3. Add branch: `main` (only main should apply to prod)
4. **Deployment protection rules**:
   - Enable **Required reviewers**: `2 reviewers`
   - Strict approval: ensure both reviewers are from different teams if possible

## Step 3: Add Environment Variables

These are **NOT secrets**—they are public configuration that CI/CD needs.

### For both `mvp` and `prod-reference` environments:

Go to **Settings** → **Environments** → select environment → **Environment variables**

Add the following (values from your Azure subscription and tfstate backend):

| Variable | Value | Example |
|----------|-------|---------|
| `AZURE_CLIENT_ID` | OIDC app registration ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure AD tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription | `11111111-1111-1111-1111-111111111111` |
| `TFSTATE_RESOURCE_GROUP` | Resource group containing tfstate | `rg-tfstate-tfstate001` |
| `TFSTATE_STORAGE_ACCOUNT` | Storage account name | `sttfstatetfstate001` |
| `TFSTATE_CONTAINER` | Blob container name | `tfstate` |

**To find these values:**

```bash
# Azure CLI
az account show --query id -o tsv              # AZURE_SUBSCRIPTION_ID
az account show --query tenantId -o tsv        # AZURE_TENANT_ID
az ad app list --filter "displayName eq 'northwind-terraform-oidc'" --query "[0].appId" -o tsv  # AZURE_CLIENT_ID

# From bootstrap output
# TFSTATE_RESOURCE_GROUP, TFSTATE_STORAGE_ACCOUNT, TFSTATE_CONTAINER
```

## Step 4: Add Environment Secrets

Secrets are encrypted and only used in the GitHub environment.

### For both environments:

Go to **Settings** → **Environments** → select environment → **Environment secrets**

Add the following (only if you are enabling SQL database):

| Secret | Value |
|--------|-------|
| `SQL_ADMIN_PASSWORD` | Azure SQL admin password (16+ characters, stored externally) |

**Important:**
- This secret is ONLY used when `enable_sql_database = true` in Terraform
- The password must be at least 16 characters (enforced by Terraform validation)
- Store this securely in a password manager; never commit it to git
- Example: `Northwind$SQL@2025!`

**Only set this when you plan to enable SQL; leaving it empty is acceptable.**

## Step 5: Configure Azure Budgets and Alerts

To avoid unexpected charges on your free $200 credit:

### Azure Portal

1. Go to **Cost Management + Billing** → **Cost Management**
2. Click **Budgets** → **Create**

### Budget 1: Early Warning

- **Name**: "Northwind MVP - Early Warning"
- **Category**: Subscription (your subscription)
- **Reset period**: Monthly
- **Amount**: $25 USD
- **Alerts**:
  - When actual cost exceeds 100% of budget → Email
  - When forecasted cost exceeds 100% of budget → Email
- Add recipients: your email

### Budget 2: Danger Zone

- **Name**: "Northwind MVP - Danger Zone"
- **Category**: Subscription (your subscription)
- **Reset period**: Monthly
- **Amount**: $75 USD
- **Alerts**:
  - When actual cost exceeds 100% of budget → Email (urgent)
  - When forecasted cost exceeds 100% of budget → Email (urgent)

### Optional: Anomaly Alert

1. Go to **Cost Management** → **Alert rules**
2. Create **Anomaly alert** (ML-based detection):
   - Type: Budget alert (optional)
   - Scope: Subscription
   - Threshold: Default (3x standard deviation)

## Step 6: Verify GitHub Actions Configuration

Before running any workflow:

1. Go to **Settings** → **Actions** → **General**
2. Ensure:
   - "Workflow permissions": `Read and write permissions`
   - "Default permissions": Keep as "Restrictive" (minimal is better)

2. Go to **Settings** → **Actions** → **Runners**
   - Use GitHub-hosted runners (ubuntu-latest is fine for Terraform)
   - No self-hosted runners needed for this MVP

## Step 7: Test Workflow Before Real Apply

### Dry Run: Validate on PR

1. Create a feature branch: `git checkout -b test/tf-validate`
2. Make a trivial change to `terraform/variables.tf` (e.g., comment)
3. Push and open a PR against `main`
4. Verify the PR workflow runs:
   - ✓ terraform fmt -check
   - ✓ terraform init
   - ✓ terraform validate
5. Merge the PR (should still run validate)

### First Plan: Manual Dispatch

1. Go to **Actions** → **Terraform**
2. Click **Run workflow**
   - `action`: select `plan`
   - `environment`: select `mvp`
3. Follow the run, approve the deployment if prompted
4. Check the plan output in the workflow logs
   - Should show: Create RG, 3 VNets, peerings, subnets, NSGs
   - Should NOT show: App Service, SQL, Bastion, VPN (defaults are off)
5. **Do NOT apply yet**—save the plan and review

### First Apply: After Review

1. Go to **Actions** → **Terraform**
2. Click **Run workflow**
   - `action`: select `apply`
   - `environment`: select `mvp`
3. The workflow requires approval (1 reviewer for mvp)
   - GitHub will notify you to approve the deployment
4. After approval, Terraform applies the saved plan
5. Monitor Azure cost dashboard for 10 minutes to ensure no surprise charges

## Cost Expectations (First Month)

After the base deployment (foundation + network only):

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| Resource Group | N/A | Free |
| 3x Virtual Networks | N/A | Free |
| Peerings | N/A | Free (within region) |
| NSGs | N/A | ~$0.50 |
| Monitoring (if enabled) | Log Analytics PerGB | ~$0.50-2 |
| **Total** | | **~$1-2 USD** |

When adding optional services:
- **Storage** (Standard LRS, no snapshots): ~$1-2/month
- **Key Vault** (standard tier): ~$0.70/month
- **App Service (B1)**: ~$10-15/month (when enabled)
- **SQL (standard tier)**: ~$100-200/month (expensive, enable last)
- **Bastion/VPN**: ~$200+/month (only enable for demo, then destroy)

**Strategy**: 
- Keep foundation + network always on (< $5/month)
- Enable storage/KV when ready for MVP (< $10/month)
- Enable App Service only when demoing (< $25/month)
- Enable Bastion/VPN 1 hour before demo, destroy after (< $10 per demo)
- Never enable SQL until absolutely necessary

## Troubleshooting

### "Deployment branch protection rules not satisfied"
- Ensure the branch matches (must be `main` for prod-reference, `main` for mvp)
- Check that the deployment is coming from the correct branch

### "Required reviewers not satisfied"
- Ensure at least 1 reviewer for mvp, 2 for prod-reference
- If no reviewers appear, check organization/team settings

### "OIDC authentication failed"
- Verify `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` in environment variables (not secrets)
- Ensure the federated credential in Azure AD matches the GitHub entity ID
- Re-run `az ad app federated-credential create` with correct subject: `repo:OWNER/REPO:environment:ENV`

### "Terraform state lock timeout"
- Another workflow is applying; wait 30 minutes or cancel the other run
- If stuck, unlock manually: `terraform force-unlock <LOCK_ID>` (requires local CLI access)

### "Storage account access denied"
- Verify the OIDC identity has **Storage Blob Data Contributor** role on the tfstate container (not the entire storage account)
- Role assignment scope must be: `/subscriptions/.../storageAccounts/.../blobServices/default/containers/tfstate`

## Next Steps

1. Complete GitHub Environments setup ✓
2. Set Azure budgets and alerts ✓
3. Verify workflow runs on PRs (validate only)
4. Run first `plan` workflow and review output
5. Run first `apply` workflow after approval
6. Incrementally enable services (Storage → App Service → SQL)
7. Monitor costs weekly for the first month

## References

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Azure Cost Management Budgets](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets)
- [GitHub OIDC with Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
