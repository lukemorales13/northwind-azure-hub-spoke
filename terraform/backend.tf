/*
  The remote backend is deliberately supplied at init time so that no state
  storage details are committed. Bootstrap the state account separately, then:

  terraform init -reconfigure \
    -backend-config="resource_group_name=rg-tfstate-<unique>" \
    -backend-config="storage_account_name=sttfstate<unique>" \
    -backend-config="container_name=tfstate" \
    -backend-config="key=northwind/mvp.tfstate" \
    -backend-config="use_azuread_auth=true"

  Do not use access keys in backend configuration. The identity that runs
  Terraform needs Storage Blob Data Contributor on the state container.
*/
