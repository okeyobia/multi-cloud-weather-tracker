# Azure Resource Group Outputs
output "resource_group_id" {
  description = "The ID of the primary resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the primary resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_secondary_id" {
  description = "The ID of the secondary resource group (if enabled)"
  value       = var.enable_secondary_region ? azurerm_resource_group.secondary[0].id : null
}

output "resource_group_secondary_name" {
  description = "The name of the secondary resource group (if enabled)"
  value       = var.enable_secondary_region ? azurerm_resource_group.secondary[0].name : null
}

# Virtual Network Outputs
output "vnet_id" {
  description = "The ID of the primary virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the primary virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "The address space of the primary virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "vnet_secondary_id" {
  description = "The ID of the secondary virtual network (if enabled)"
  value       = var.enable_secondary_region ? azurerm_virtual_network.secondary[0].id : null
}

# Subnet Outputs
output "aks_subnet_id" {
  description = "The ID of the AKS node pool subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "The name of the AKS node pool subnet"
  value       = azurerm_subnet.aks.name
}

output "app_subnet_id" {
  description = "The ID of the app subnet"
  value       = azurerm_subnet.apps.id
}

output "postgresql_subnet_id" {
  description = "The ID of the PostgreSQL subnet"
  value       = azurerm_subnet.postgresql.id
}

# Key Vault Outputs
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

# Log Analytics Outputs
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# Application Insights Outputs
output "application_insights_id" {
  description = "The ID of the Application Insights instance"
  value       = azurerm_application_insights.main.id
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# AKS Cluster Outputs
output "aks_cluster_id" {
  description = "The ID of the primary AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_name" {
  description = "The name of the primary AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the primary AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_kube_config_raw" {
  description = "The raw kubeconfig content for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_client_certificate" {
  description = "The client certificate for AKS cluster authentication"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "aks_client_key" {
  description = "The client key for AKS cluster authentication"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "aks_cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "aks_host" {
  description = "The Kubernetes cluster API server host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
}

output "aks_secondary_cluster_id" {
  description = "The ID of the secondary AKS cluster (if enabled)"
  value       = var.enable_secondary_region ? azurerm_kubernetes_cluster.secondary[0].id : null
}

output "aks_secondary_cluster_name" {
  description = "The name of the secondary AKS cluster (if enabled)"
  value       = var.enable_secondary_region ? azurerm_kubernetes_cluster.secondary[0].name : null
}

# ACR Outputs
output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "The login server URL for the ACR"
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_admin_username" {
  description = "The admin username for ACR"
  value       = azurerm_container_registry.main.admin_username
}

output "acr_admin_password" {
  description = "The admin password for ACR"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# PostgreSQL Outputs
output "postgresql_server_id" {
  description = "The ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_server_name" {
  description = "The name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_administrator_login" {
  description = "The administrator login for PostgreSQL"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "postgresql_connection_string" {
  description = "The connection string for PostgreSQL (using Key Vault)"
  value       = "Stored in Key Vault: ${azurerm_key_vault_secret.postgresql_connection_string.name}"
}

output "postgresql_password_key_vault_secret_id" {
  description = "The Key Vault secret ID for PostgreSQL password"
  value       = azurerm_key_vault_secret.postgresql_password.id
}

output "postgresql_connection_string_key_vault_secret_id" {
  description = "The Key Vault secret ID for PostgreSQL connection string"
  value       = azurerm_key_vault_secret.postgresql_connection_string.id
}

output "postgresql_secondary_server_id" {
  description = "The ID of the secondary PostgreSQL Flexible Server (if enabled)"
  value       = var.enable_secondary_region ? azurerm_postgresql_flexible_server.secondary[0].id : null
}

output "postgresql_secondary_server_fqdn" {
  description = "The FQDN of the secondary PostgreSQL Flexible Server (if enabled)"
  value       = var.enable_secondary_region ? azurerm_postgresql_flexible_server.secondary[0].fqdn : null
}

output "postgresql_database_name" {
  description = "The name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

# Private DNS Zone Outputs
output "postgresql_private_dns_zone_id" {
  description = "The ID of the PostgreSQL private DNS zone"
  value       = azurerm_private_dns_zone.postgresql.id
}

output "postgresql_private_dns_zone_name" {
  description = "The name of the PostgreSQL private DNS zone"
  value       = azurerm_private_dns_zone.postgresql.name
}

# Front Door Outputs
output "front_door_id" {
  description = "The ID of the Azure Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "front_door_name" {
  description = "The name of the Azure Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "front_door_endpoint_id" {
  description = "The ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.id
}

output "front_door_endpoint_host_name" {
  description = "The host name of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "front_door_endpoint_fqdn" {
  description = "The FQDN of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.fqdn
}

output "front_door_waf_policy_id" {
  description = "The ID of the Front Door WAF policy"
  value       = var.enable_front_door_waf ? azurerm_cdn_frontdoor_firewall_policy.main[0].id : null
}

output "front_door_custom_domain" {
  description = "The custom domain for Front Door (if configured)"
  value       = var.front_door_custom_domain != "" ? var.front_door_custom_domain : null
}

output "front_door_secondary_endpoint_host_name" {
  description = "The host name of the secondary Front Door endpoint (if enabled)"
  value       = var.enable_secondary_region ? azurerm_cdn_frontdoor_endpoint.secondary[0].host_name : null
}

# Traffic Manager Outputs
output "traffic_manager_profile_id" {
  description = "The ID of the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.main.id
}

output "traffic_manager_profile_name" {
  description = "The name of the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.main.name
}

output "traffic_manager_fqdn" {
  description = "The FQDN of the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.main.fqdn
}

output "traffic_manager_routing_method" {
  description = "The routing method used by Traffic Manager"
  value       = azurerm_traffic_manager_profile.main.traffic_routing_method
}

output "traffic_manager_primary_endpoint_id" {
  description = "The ID of the primary Traffic Manager endpoint"
  value       = azurerm_traffic_manager_azure_endpoint.primary.id
}

output "traffic_manager_secondary_endpoint_id" {
  description = "The ID of the secondary Traffic Manager endpoint (if enabled)"
  value       = var.enable_secondary_region ? azurerm_traffic_manager_azure_endpoint.secondary[0].id : null
}

# Storage Account Outputs
output "storage_account_id" {
  description = "The ID of the storage account for logs"
  value       = azurerm_storage_account.logs.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.logs.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint URL"
  value       = azurerm_storage_account.logs.primary_blob_endpoint
}

# Managed Identity Outputs
output "aks_managed_identity_id" {
  description = "The principal ID of the AKS cluster managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "aks_managed_identity_client_id" {
  description = "The client ID of the AKS cluster managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "kubelet_managed_identity_id" {
  description = "The principal ID of the AKS kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}

# Connection Strings and Access Information
output "connection_info" {
  description = "Summary of connection information for the infrastructure"
  value = {
    kubernetes_api_server = azurerm_kubernetes_cluster.main.kube_config[0].host
    postgresql_server     = azurerm_postgresql_flexible_server.main.fqdn
    front_door_endpoint   = azurerm_cdn_frontdoor_endpoint.main.host_name
    traffic_manager_fqdn  = azurerm_traffic_manager_profile.main.fqdn
    acr_login_server      = azurerm_container_registry.main.login_server
    key_vault_uri         = azurerm_key_vault.main.vault_uri
  }
}

# Tags applied to resources
output "tags" {
  description = "The tags applied to resources"
  value       = var.tags
}

# Environment information
output "environment_info" {
  description = "Summary of environment configuration"
  value = {
    project_name         = var.project_name
    environment          = var.environment
    primary_region       = var.azure_region
    secondary_region     = var.enable_secondary_region ? var.azure_secondary_region : "disabled"
    kubernetes_version   = var.kubernetes_version
    postgresql_version   = var.postgresql_version
    traffic_manager_type = var.traffic_manager_routing_method
  }
}
