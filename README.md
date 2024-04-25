# demo-tf-actions-azure

This repository is a demo of using GitHub Actions to deploy to Azure and monitor for configuration drift.

## GitHub Actions

Included are two GitHub Actions:

- [`terraform-plan.yml`](.github/workflows/terraform-plan.yml): Executes `terraform plan` against pull requets, and when merging to main will run `apply` to deploy the configuration.
- [`terraform-audit.yml`](.github/workflows/terraform-audit.yml): Example of a GitHub Action which could be run as a scheduled job (configured to run manually for this demo). This Action will have a failure status if the deployed configuration differs from the configuration in `main`.

## Authentication to Azure

The GitHub Actions authenticate to Azure as a service principal; however, instead of managing secrets in GitHub, this implements Federated Authentication with OIDC.

Documentation:

- [Configuring OpenID Connect in Azure - GitHub Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Authenticate to Azure from GitHub Action workflows | Microsoft Learn](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux)

## Infrastructure

- [`main.tf`](infra/main.tf): Expects an existing resource group and will create a storage account with the specified configuration.

### Terraform State

The Terraform state is in an Azure Blob Storage container. See the [Backend Type: azurerm Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm) on the Terraform site for parameters.

We are again using OIDC to authenticate to the state store as a service principal.

## Demo Scenarios

- Creating a pull request and seeing the result of `terraform plan` in the Pull Request comments and Actions log
- Running the Terraform Audit action manually with a good configuration
- Changing your storage account configuration and running the Terraform Audit action to see the error status

## Running Locally

To test/run locally, start a Codespace against this repository or clone to your local machine.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ChrisRomp/demo-tf-actions-azure?quickstart=1)

Prerequisites (installed automatically with Codespaces):

- Terraform
- Azure CLI

You can see the expected environment variables defined in the [`.env.sample`](.env.sample) file.

| Variable | Required/Optional | Description |
| --- | --- | --- |
| `DEPLOY_RESOURCE_GROUP` | Required | Azure Resource Group used for deploying resources |
| `DEPLOY_STORAGE_ACCOUNT_NAME` | Required | The name of the storage account to be deployed/managed by Terraform |
| `STATE_RESOURCE_GROUP` | Required if storing state in Azure | Resource group used for Terraform state |
| `STATE_STORAGE_ACCOUNT_NAME` | Required if storing state in Azure |  Storage account name for Terraform state |
| `STATE_CONTAINER_NAME` | Required if storing state in Azure |  Storage account container for Terraform state |
| `STATE_KEY_NAME` | Required if storing state in Azure |  The name of the state file in the container. |

### Authenticating to Azure

Log into Azure CLI with `az login`.

> [!TIP]
> If using Codespaces or a remote host, it may work better to authenticate with a device code: `az login --use-device-code`
>
> Docs: [Sign in with Azure CLI interactively at a command line | Microsoft Learn](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively)

### Terraform Init

From the `infra` folder, you can configure your system to use local state files simply by running:

```bash
terraform init
```

If you wish to use a state file stored in Azure in the same manner that GitHub Actions is configured to, you can pass parameters to the init command:

```bash
terraform init \
  -backend-config="resource_group_name=$STATE_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STATE_STORAGE_ACCOUNT_NAME" \
  -backend-config="container_name=$STATE_CONTAINER_NAME" \
  -backend-config="key=$STATE_KEY_NAME"
```

### Terraform Plan

```bash
terraform plan -out main.tfplan \
  -var "resource_group_name=$DEPLOY_RESOURCE_GROUP" \
  -var "storage_account_name=$DEPLOY_STORAGE_ACCOUNT_NAME"
```

### Terraform Apply

```bash
terraform apply main.tfplan
```
