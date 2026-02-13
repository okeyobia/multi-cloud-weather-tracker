# Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-rg-${var.environment}"
  location = var.azure_region

  tags = merge(var.tags, {
    Name = "${var.project_name}-rg-${var.environment}"
  })
}

# Secondary Resource Group (for disaster recovery)
resource "azurerm_resource_group" "secondary" {
  count    = var.enable_secondary_region ? 1 : 0
  name     = "${var.project_name}-rg-dr-${var.environment}"
  location = var.azure_secondary_region

  tags = merge(var.tags, {
    Name = "${var.project_name}-rg-dr-${var.environment}"
  })
}

# Virtual Network for AKS
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet-${var.environment}"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-vnet-${var.environment}"
  })
}

# Subnet for AKS nodes
resource "azurerm_subnet" "aks_nodes" {
  name                 = "${var.project_name}-subnet-nodes-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/16"]
}

# Subnet for applications
resource "azurerm_subnet" "apps" {
  name                 = "${var.project_name}-subnet-apps-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.2.0.0/16"]
}

# Network Security Group for AKS
resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_name}-nsg-aks-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-nsg-aks-${var.environment}"
  })
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-logs-${var.environment}"
  })
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-insights-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  retention_in_days   = var.log_analytics_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-insights-${var.environment}"
  })
}

# Storage Account for logs and diagnostics
resource "azurerm_storage_account" "logs" {
  name                     = replace("${var.project_name}logs${var.environment}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant storage
  https_traffic_only_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-logs-storage-${var.environment}"
  })
}

# Storage Account Network Rules (only allow from AKS VNet)
resource "azurerm_storage_account_network_rules" "logs" {
  storage_account_id         = azurerm_storage_account.logs.id
  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.aks_nodes.id]
  bypass                     = ["AzureServices"]
}

# Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_disk_encryption      = true
  enabled_for_template_deployment  = true
  purge_protection_enabled         = var.environment == "prod"
  soft_delete_retention_days       = var.environment == "prod" ? 90 : 7

  network_acls {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-kv-${var.environment}"
  })
}

# Key Vault Access Policy for current user
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Purge"
  ]
}
