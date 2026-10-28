# Azure CLI (`az`) Master Command Reference: Start to End

A complete, production-grade handbook for Cloud Engineers, AI Engineers, and Forward Deployed Engineers (FDE).

---

## Table of Contents
1. [Authentication & Account Management](#1-authentication--account-management)
2. [Resource Groups & Hierarchy](#2-resource-groups--hierarchy)
3. [Azure AI Services & Search (AI/FDE Core)](#3-azure-ai-services--search-aifde-core)
4. [Storage Accounts & Blob Management](#4-storage-accounts--blob-management)
5. [Enterprise Security & Azure Key Vault](#5-enterprise-security--azure-key-vault)
6. [App Services & Web Apps](#6-app-services--web-apps)
7. [Serverless Computing (Azure Functions)](#7-serverless-computing-azure-functions)
8. [Databases (Cosmos DB & Azure SQL)](#8-databases-cosmos-db--azure-sql)
9. [Networking & Virtual Firewalls](#9-networking--virtual-firewalls)
10. [Observability, Monitoring & Cost Control](#10-observability-monitoring--cost-control)
11. [Resource Clean-Up & Teardown](#11-resource-clean-up--teardown)

---

## 1. Authentication & Account Management

### Log in
```powershell
# Interactive browser login
az login

# Device code login (best for remote shells/sandboxes)
az login --use-device-code

# Log in targeting a specific corporate tenant
az login --tenant "<tenant-id>" --use-device-code

# Check CLI version and updates
az version
```

### Subscriptions
```powershell
# List all accessible subscriptions in a table
az account list --output table

# Show currently active subscription
az account show --output json

# Switch to a different subscription
az account set --subscription "<subscription-id-or-name>"

# Clear cached credentials / logout
az logout
```

---

## 2. Resource Groups & Hierarchy

Resource Groups (RG) logically organize all related resources.

```powershell
# List all resource groups
az group list --output table

# Create a new resource group
az group create --name "rg-azure-explorer" --location "uaenorth"

# Inspect resource group details and provisioning state
az group show --name "rg-azure-explorer" --output table

# Check what resources exist inside a specific resource group
az resource list --resource-group "rg-azure-explorer" --output table

# Check all available datacenter locations
az account list-locations --query "[].{Region:name, DisplayName:displayName}" --output table
```

---

## 3. Azure AI Services & Search (AI/FDE Core)

Everything an AI Engineer or Forward Deployed Engineer uses to build RAG, agentic workflows, and OCR.

### Azure AI Multi-Service (Vision, Speech, Document Intelligence, Language)
```powershell
# Check available AI kinds in a region
az cognitiveservices account list-kinds --output table

# Check supported SKUs in your allowed region (e.g. uaenorth)
az cognitiveservices account list-skus --location "uaenorth" --output table

# Create an Azure AI Multi-Service account
az cognitiveservices account create `
    --name "explore-ai-hub" `
    --resource-group "rg-azure-explorer" `
    --location "uaenorth" `
    --kind AIServices `
    --sku S0 `
    --yes

# Show endpoint and status
az cognitiveservices account show `
    --name "explore-ai-hub" `
    --resource-group "rg-azure-explorer" `
    --query "{Name:name, Status:properties.provisioningState, Endpoint:properties.endpoint}" `
    --output table

# Retrieve API keys for client code
az cognitiveservices account keys list `
    --name "explore-ai-hub" `
    --resource-group "rg-azure-explorer" `
    --output table

# Regenerate key (key1 or key2) for zero-downtime rotation
az cognitiveservices account keys regenerate `
    --name "explore-ai-hub" `
    --resource-group "rg-azure-explorer" `
    --key-name key1
```

### Azure AI Search (Vector Database for RAG)
```powershell
# Create an Azure AI Search service (using permanently 100% Free tier)
# Note: Korea Central has active Free-tier capacity under Azure for Students policy
az search service create `
    --name "search-explorer-01" `
    --resource-group "rg-azure-explorer" `
    --location "koreacentral" `
    --sku free

# List primary and secondary admin query keys
az search admin-key show `
    --service-name "search-explorer-01" `
    --resource-group "rg-azure-explorer" `
    --output table

# Show search service endpoint
az search service show `
    --name "search-explorer-01" `
    --resource-group "rg-azure-explorer" `
    --query "properties.endpoint" `
    --output tsv
```

---

## 4. Storage Accounts & Blob Management

Used for data lakes, unstructured documents (PDFs for RAG), and static websites.

```powershell
# Create a Storage Account (names must be unique, lowercase, 3-24 chars)
az storage account create `
    --name "stexplore12345" `
    --resource-group "rg-azure-explorer" `
    --location "uaenorth" `
    --sku Standard_LRS `
    --kind StorageV2

# Retrieve storage connection string
az storage account show-connection-string `
    --name "stexplore12345" `
    --resource-group "rg-azure-explorer" `
    --output tsv

# Enable Static Website hosting ($web container)
az storage blob service-properties update `
    --account-name "stexplore12345" `
    --static-website `
    --index-document index.html `
    --404-document 404.html

# Upload a file to Blob storage
az storage blob upload `
    --account-name "stexplore12345" `
    --container-name '$web' `
    --file "index.html" `
    --name "index.html"

# Upload an entire directory of documents (e.g. PDFs for vector search)
az storage blob upload-batch `
    --account-name "stexplore12345" `
    --destination "raw-docs" `
    --source "./my-pdfs"

# Get public web endpoint URL
az storage account show `
    --name "stexplore12345" `
    --resource-group "rg-azure-explorer" `
    --query "primaryEndpoints.web" `
    --output tsv
```

---

## 5. Enterprise Security & Azure Key Vault

How enterprise architectures store API tokens, secrets, and database passwords securely.

```powershell
# Create an Azure Key Vault
az keyvault create `
    --name "kv-explore-01" `
    --resource-group "rg-azure-explorer" `
    --location "uaenorth"

# Store a secret
az keyvault secret set `
    --vault-name "kv-explore-01" `
    --name "OpenRouterApiKey" `
    --value "sk-or-v1-my-secret-key"

# Retrieve secret value
az keyvault secret show `
    --vault-name "kv-explore-01" `
    --name "OpenRouterApiKey" `
    --query "value" `
    --output tsv

# List all secrets in vault
az keyvault secret list --vault-name "kv-explore-01" --output table
```

---

## 6. App Services & Web Apps

Hosting production web apps, REST APIs, and frontends.

```powershell
# Create a Free Tier (F1) App Service Plan
az appservice plan create `
    --name "asp-free-plan" `
    --resource-group "rg-azure-explorer" `
    --location "uaenorth" `
    --sku F1 `
    --is-linux

# Deploy a Web App (Python, Node, or .NET)
az webapp create `
    --name "webapp-explore-01" `
    --resource-group "rg-azure-explorer" `
    --plan "asp-free-plan" `
    --runtime "PYTHON:3.11"

# Stream live application logs to your terminal
az webapp log tail --name "webapp-explore-01" --resource-group "rg-azure-explorer"

# Restart a web app
az webapp restart --name "webapp-explore-01" --resource-group "rg-azure-explorer"

# Get the live URL
az webapp show `
    --name "webapp-explore-01" `
    --resource-group "rg-azure-explorer" `
    --query "defaultHostName" `
    --output tsv
```

---

## 7. Serverless Computing (Azure Functions)

Microservices triggered by HTTP, schedules (cron), or blob uploads. (1M calls free/mo).

```powershell
# Create a Function App
az functionapp create `
    --name "func-explore-01" `
    --resource-group "rg-azure-explorer" `
    --storage-account "stexplore12345" `
    --consumption-plan-location "uaenorth" `
    --runtime python `
    --runtime-version 3.11 `
    --functions-version 4 `
    --os-type Linux

# List running functions inside your app
az functionapp function list `
    --name "func-explore-01" `
    --resource-group "rg-azure-explorer" `
    --output table
```

---

## 8. Databases (Cosmos DB & Azure SQL)

```powershell
# Create Azure Cosmos DB with Free Tier enabled ($0 cost, 1000 RU/s + 25GB free)
az cosmosdb create `
    --name "cosmos-explore-01" `
    --resource-group "rg-azure-explorer" `
    --enable-free-tier true `
    --default-consistency-level Session `
    --locations regionName="uaenorth" failoverPriority=0

# Retrieve Cosmos DB primary connection key
az cosmosdb keys list `
    --name "cosmos-explore-01" `
    --resource-group "rg-azure-explorer" `
    --output table
```

---

## 9. Networking & Virtual Firewalls

```powershell
# Create a Virtual Network (VNet) with a default Subnet
az network vnet create `
    --name "vnet-explore" `
    --resource-group "rg-azure-explorer" `
    --location "uaenorth" `
    --address-prefix "10.0.0.0/16" `
    --subnet-name "subnet-default" `
    --subnet-prefix "10.0.1.0/24"

# Create a Network Security Group (NSG)
az network nsg create `
    --name "nsg-explore" `
    --resource-group "rg-azure-explorer" `
    --location "uaenorth"

# Add an inbound firewall rule allowing HTTPS traffic (Port 443)
az network nsg rule create `
    --name "AllowHTTPS" `
    --nsg-name "nsg-explore" `
    --resource-group "rg-azure-explorer" `
    --priority 100 `
    --destination-port-ranges 443 `
    --protocol Tcp `
    --access Allow `
    --direction Inbound
```

---

## 10. Observability, Monitoring & Cost Control

```powershell
# Check current month-to-date spending
az consumption usage list `
    --start-date "2026-10-01" `
    --end-date "2026-10-26" `
    --output table

# View real-time activity log of who did what in the subscription
az monitor activity-log list `
    --resource-group "rg-azure-explorer" `
    --max-events 20 `
    --output table

# Create a Log Analytics Workspace
az monitor log-analytics workspace create `
    --resource-group "rg-azure-explorer" `
    --workspace-name "law-explore-01" `
    --location "uaenorth"
```

---

## 11. Resource Clean-Up & Teardown

> [!CAUTION]
> As an engineer, always delete or stop unused resources when done to protect student credits.

```powershell
# Delete a single resource (e.g. Cognitive Services)
az cognitiveservices account delete `
    --name "explore-ai-hub" `
    --resource-group "rg-azure-explorer"

# PURGE a deleted Cognitive Services account (Azure soft-deletes by default for 48h)
az cognitiveservices account purge `
    --name "explore-ai-hub" `
    --location "uaenorth" `
    --resource-group "rg-azure-explorer"

# THE ULTIMATE CLEANUP: Delete the entire Resource Group and EVERYTHING in it
# The --no-wait flag runs deletion asynchronously in the cloud
az group delete --name "rg-azure-explorer" --yes --no-wait

# Verify deletion status
az group list --output table
```
