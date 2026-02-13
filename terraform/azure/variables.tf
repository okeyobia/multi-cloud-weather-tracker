# Azure Core Configuration
variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"

  validation {
    condition     = can(regex("^[A-Z][a-z\\s]+$", var.azure_region))
    error_message = "Azure region must be a valid Azure region name"
  }
}

variable "azure_secondary_region" {
  description = "Secondary Azure region for disaster recovery"
  type        = string
  default     = "West US 2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "weather-tracker"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 20 chars"
  }
}

# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Managed     = "Terraform"
    Project     = "weather-tracker"
    Environment = "prod"
  }
}

# AKS Configuration
variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[8-9]|3[0-9])$", var.aks_kubernetes_version))
    error_message = "Kubernetes version must be 1.28 or later"
  }
}

variable "aks_node_count" {
  description = "Initial number of nodes in AKS cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 100
    error_message = "Node count must be between 1 and 100"
  }
}

variable "aks_min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1

  validation {
    condition     = var.aks_min_node_count >= 1
    error_message = "Minimum node count must be at least 1"
  }
}

variable "aks_max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10

  validation {
    condition     = var.aks_max_node_count >= 1
    error_message = "Maximum node count must be at least 1"
  }
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_enable_auto_scaling" {
  description = "Enable auto-scaling for AKS"
  type        = bool
  default     = true
}

variable "aks_enable_rbac" {
  description = "Enable RBAC for AKS"
  type        = bool
  default     = true
}

variable "aks_network_plugin" {
  description = "Network plugin for AKS (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.aks_network_plugin)
    error_message = "Network plugin must be azure or kubenet"
  }
}

variable "aks_service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aks_docker_bridge_cidr" {
  description = "CIDR for Docker bridge"
  type        = string
  default     = "172.17.0.1/16"
}

variable "aks_pod_cidr" {
  description = "CIDR for pod network"
  type        = string
  default     = "10.244.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "Kubernetes DNS service IP"
  type        = string
  default     = "10.1.0.10"
}

variable "aks_enable_private_cluster" {
  description = "Enable private AKS cluster"
  type        = bool
  default     = false
}

variable "aks_enable_http_application_routing" {
  description = "Enable HTTP Application Routing"
  type        = bool
  default     = false
}

variable "aks_enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = true
}

variable "aks_enable_monitoring" {
  description = "Enable monitoring with Container Insights"
  type        = bool
  default     = true
}

# Azure PostgreSQL Configuration
variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "14"

  validation {
    condition     = contains(["11", "12", "13", "14", "15"], var.postgresql_version)
    error_message = "PostgreSQL version must be 11, 12, 13, 14, or 15"
  }
}

variable "postgresql_sku_name" {
  description = "SKU name for PostgreSQL"
  type        = string
  default     = "B_Standard_B2s"
}

variable "postgresql_storage_mb" {
  description = "Storage size in MB for PostgreSQL"
  type        = number
  default     = 32768  # 32GB

  validation {
    condition     = var.postgresql_storage_mb >= 32768 && var.postgresql_storage_mb <= 1048576
    error_message = "Storage must be between 32GB and 1TB"
  }
}

variable "postgresql_backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.postgresql_backup_retention_days >= 7 && var.postgresql_backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days"
  }
}

variable "postgresql_administrator_name" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "psqladmin"
  sensitive   = true
}

variable "postgresql_administrator_password" {
  description = "Administrator password for PostgreSQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.postgresql_administrator_password) >= 8
    error_message = "Password must be at least 8 characters"
  }
}

variable "postgresql_database_name" {
  description = "Initial database name"
  type        = string
  default     = "weatherdb"
}

variable "postgresql_enable_geo_redundancy" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = true
}

variable "postgresql_enable_ssl" {
  description = "Enforce SSL connection"
  type        = bool
  default     = true
}

variable "postgresql_enable_monitoring" {
  description = "Enable monitoring for PostgreSQL"
  type        = bool
  default     = true
}

# Azure Front Door Configuration
variable "front_door_sku" {
  description = "Front Door SKU (Standard or Premium)"
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku)
    error_message = "SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  }
}

variable "front_door_enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "front_door_waf_policy_mode" {
  description = "WAF policy mode (Detection or Prevention)"
  type        = string
  default     = "Detection"

  validation {
    condition     = contains(["Detection", "Prevention"], var.front_door_waf_policy_mode)
    error_message = "WAF mode must be Detection or Prevention"
  }
}

variable "front_door_custom_domain_name" {
  description = "Custom domain name for Front Door"
  type        = string
  default     = ""
}

variable "front_door_certificate_type" {
  description = "Certificate type (ManagedCertificate or CustomerCertificate)"
  type        = string
  default     = "ManagedCertificate"
}

# Traffic Manager Configuration
variable "traffic_manager_profile_name" {
  description = "Traffic Manager profile name"
  type        = string
  default     = ""
}

variable "traffic_manager_routing_method" {
  description = "Routing method (Geographic, Priority, Performance, Weighted, MultiValue)"
  type        = string
  default     = "Performance"

  validation {
    condition     = contains(["AzureEndpoints", "ExternalEndpoints", "NestedEndpoints", "Geographic", "Priority", "Performance", "Weighted", "MultiValue"], var.traffic_manager_routing_method)
    error_message = "Invalid routing method"
  }
}

variable "traffic_manager_protocol" {
  description = "Protocol for health checks (HTTP, HTTPS, TCP)"
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.traffic_manager_protocol)
    error_message = "Protocol must be HTTP, HTTPS, or TCP"
  }
}

variable "traffic_manager_port" {
  description = "Port for health checks"
  type        = number
  default     = 443

  validation {
    condition     = var.traffic_manager_port >= 1 && var.traffic_manager_port <= 65535
    error_message = "Port must be between 1 and 65535"
  }
}

variable "traffic_manager_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "traffic_manager_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.traffic_manager_interval >= 30 && var.traffic_manager_interval <= 30
    error_message = "Interval must be 30 seconds"
  }
}

variable "traffic_manager_tolerated_failures" {
  description = "Number of tolerated consecutive failures"
  type        = number
  default     = 3

  validation {
    condition     = var.traffic_manager_tolerated_failures >= 0 && var.traffic_manager_tolerated_failures <= 9
    error_message = "Tolerated failures must be between 0 and 9"
  }
}

variable "traffic_manager_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 10

  validation {
    condition     = var.traffic_manager_timeout >= 5 && var.traffic_manager_timeout <= 30
    error_message = "Timeout must be between 5 and 30 seconds"
  }
}

variable "enable_secondary_region" {
  description = "Enable secondary region deployment"
  type        = bool
  default     = false
}

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention must be between 30 and 730 days"
  }
}
