# Subnet for PostgreSQL server
resource "azurerm_subnet" "postgresql" {
  name                 = "${var.project_name}-subnet-db-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.3.0.0/16"]

  service_delegation {
    name = "Microsoft.DBforPostgreSQL/flexibleServers"

    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action"
    ]
  }
}

# Network Security Group for PostgreSQL
resource "azurerm_network_security_group" "postgresql" {
  name                = "${var.project_name}-nsg-psql-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-nsg-psql-${var.environment}"
  })
}

# Allow PostgreSQL from AKS subnet
resource "azurerm_network_security_rule" "postgresql_from_aks" {
  name                        = "allow-postgres-from-aks"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "10.1.0.0/16"  # AKS subnet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.postgresql.name
}

# Associate NSG with PostgreSQL subnet
resource "azurerm_subnet_network_security_group_association" "postgresql" {
  subnet_id                 = azurerm_subnet.postgresql.id
  network_security_group_id = azurerm_network_security_group.postgresql.id
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-pdns-psql-${var.environment}"
  })
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${var.project_name}-psql-vnet-link-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name
}

# Azure Database for PostgreSQL
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-psql-${var.environment}"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  version                = var.postgresql_version
  administrator_login    = var.postgresql_administrator_name
  administrator_password = var.postgresql_administrator_password

  sku_name                     = var.postgresql_sku_name
  storage_mb                   = var.postgresql_storage_mb
  backup_retention_days        = var.postgresql_backup_retention_days
  geo_redundant_backup_enabled = var.postgresql_enable_geo_redundancy

  delegated_subnet_id             = azurerm_subnet.postgresql.id
  private_dns_zone_id             = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled   = false

  # High Availability
  zone = "1"
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  # Backups
  backup_retention_days = var.postgresql_backup_retention_days

  # Maintenance window
  maintenance_window {
    day_of_week  = 0  # Sunday
    start_hour   = 3
    start_minute = 0
  }

  # SSL enforcement
  ssl_enforcement_enabled = var.postgresql_enable_ssl

  tags = merge(var.tags, {
    Name = "${var.project_name}-psql-${var.environment}"
  })

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgresql
  ]

  lifecycle {
    ignore_changes = [zone]
  }
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "weather" {
  name              = var.postgresql_database_name
  server_id         = azurerm_postgresql_flexible_server.main.id
  charset           = "UTF8"
  collation         = "en_US.utf8"
}

# PostgreSQL Server Configuration for performance
resource "azurerm_postgresql_flexible_server_configuration" "shared_preload_libraries" {
  name       = "shared_preload_libraries"
  server_id  = azurerm_postgresql_flexible_server.main.id
  value      = "PGAZ,pg_stat_statements"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name       = "log_statement"
  server_id  = azurerm_postgresql_flexible_server.main.id
  value      = "ALL"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_min_duration_statement" {
  name       = "log_min_duration_statement"
  server_id  = azurerm_postgresql_flexible_server.main.id
  value      = "1000"
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name       = "max_connections"
  server_id  = azurerm_postgresql_flexible_server.main.id
  value      = "100"
}

# Firewall rule for Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Key Vault secret for PostgreSQL password
resource "azurerm_key_vault_secret" "postgresql_password" {
  name         = "${var.project_name}-postgresql-password"
  value        = var.postgresql_administrator_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Key Vault secret for PostgreSQL connection string
resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  name         = "${var.project_name}-postgresql-connection-string"
  value        = "postgresql://${var.postgresql_administrator_name}:${var.postgresql_administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Diagnostic settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  count              = var.postgresql_enable_monitoring ? 1 : 0
  name               = "${var.project_name}-psql-diag-${var.environment}"
  target_resource_id = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Secondary region PostgreSQL
resource "azurerm_postgresql_flexible_server" "secondary" {
  count = var.enable_secondary_region ? 1 : 0

  name                   = "${var.project_name}-psql-dr-${var.environment}"
  location               = azurerm_resource_group.secondary[0].location
  resource_group_name    = azurerm_resource_group.secondary[0].name
  version                = var.postgresql_version
  administrator_login    = var.postgresql_administrator_name
  administrator_password = var.postgresql_administrator_password

  sku_name                     = var.postgresql_sku_name
  storage_mb                   = var.postgresql_storage_mb
  backup_retention_days        = var.postgresql_backup_retention_days
  geo_redundant_backup_enabled = var.postgresql_enable_geo_redundancy

  delegated_subnet_id             = azurerm_subnet.secondary_postgresql[0].id
  private_dns_zone_id             = azurerm_private_dns_zone.secondary_postgresql[0].id
  public_network_access_enabled   = false

  zone = "1"
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-psql-dr-${var.environment}"
  })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.secondary_postgresql[0]]
}

# Secondary PostgreSQL resources
resource "azurerm_subnet" "secondary_postgresql" {
  count                = var.enable_secondary_region ? 1 : 0
  name                 = "${var.project_name}-subnet-db-dr-${var.environment}"
  resource_group_name  = azurerm_resource_group.secondary[0].name
  virtual_network_name = azurerm_virtual_network.secondary[0].name
  address_prefixes     = ["10.3.0.0/16"]

  service_delegation {
    name = "Microsoft.DBforPostgreSQL/flexibleServers"
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}

resource "azurerm_private_dns_zone" "secondary_postgresql" {
  count               = var.enable_secondary_region ? 1 : 0
  name                = "postgres-dr.database.azure.com"
  resource_group_name = azurerm_resource_group.secondary[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "secondary_postgresql" {
  count                 = var.enable_secondary_region ? 1 : 0
  name                  = "${var.project_name}-psql-dr-vnet-link-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.secondary_postgresql[0].name
  virtual_network_id    = azurerm_virtual_network.secondary[0].id
  resource_group_name   = azurerm_resource_group.secondary[0].name
}
