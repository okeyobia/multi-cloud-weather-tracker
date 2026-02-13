# Managed Identity for AKS cluster
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.project_name}-aks-identity-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = merge(var.tags, {
    Name = "${var.project_name}-aks-identity-${var.environment}"
  })
}

# Managed Identity for kubelet
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.project_name}-kubelet-identity-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = merge(var.tags, {
    Name = "${var.project_name}-kubelet-identity-${var.environment}"
  })
}

# Role assignment for AKS identity on VNet
resource "azurerm_role_assignment" "aks_network" {
  scope              = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id       = azurerm_user_assigned_identity.aks.principal_id
}

# Role assignment for kubelet identity on VNet
resource "azurerm_role_assignment" "kubelet_network" {
  scope              = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id       = azurerm_user_assigned_identity.kubelet.principal_id
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = replace("${var.project_name}acr${var.environment}", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-acr-${var.environment}"
  })
}

# Role assignment for kubelet to pull from ACR
resource "azurerm_role_assignment" "kubelet_acr" {
  scope              = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_user_assigned_identity.kubelet.principal_id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.aks_kubernetes_version

  # Default node pool
  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks_nodes.id

    enable_auto_scaling = var.aks_enable_auto_scaling
    min_count           = var.aks_min_node_count
    max_count           = var.aks_max_node_count

    max_pods = 110
    os_disk_size_gb = 128
    os_sku = "Ubuntu"
    type   = "VirtualMachineScaleSets"

    tags = merge(var.tags, {
      Name = "${var.project_name}-nodepool-default-${var.environment}"
    })
  }

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Kubelet identity
  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  # Network configuration
  network_profile {
    network_plugin     = var.aks_network_plugin
    network_policy     = "azure"
    service_cidr       = var.aks_service_cidr
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    dns_service_ip     = var.aks_dns_service_ip
    load_balancer_sku  = "standard"
  }

  # RBAC
  role_based_access_control_enabled = var.aks_enable_rbac

  # API server access
  api_server_access_profile {
    authorized_ip_ranges = []  # Allow all by default, restrict in terraform.tfvars
  }

  # Add-ons
  addon_profile {
    http_application_routing {
      enabled = var.aks_enable_http_application_routing
    }

    azure_policy {
      enabled = var.aks_enable_azure_policy
    }

    oms_agent {
      enabled                    = var.aks_enable_monitoring
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  # Monitoring
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
    disable_cost_analysis = false
  }

  # Security
  private_cluster_enabled             = var.aks_enable_private_cluster
  automatic_channel_upgrade           = "patch"
  maintenance_window {
    weekly {
      day   = "Sunday"
      hour  = 2
    }
  }

  managed_outbound_ip_count = 1

  depends_on = [
    azurerm_role_assignment.aks_network,
    azurerm_role_assignment.kubelet_network
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-aks-${var.environment}"
  })

  lifecycle {
    ignore_changes = [
      kubernetes_version,  # Allow manual upgrades
      default_node_pool[0].node_count
    ]
  }
}

# Secondary AKS cluster for disaster recovery
resource "azurerm_kubernetes_cluster" "secondary" {
  count = var.enable_secondary_region ? 1 : 0

  name                = "${var.project_name}-aks-dr-${var.environment}"
  location            = azurerm_resource_group.secondary[0].location
  resource_group_name = azurerm_resource_group.secondary[0].name
  dns_prefix          = "${var.project_name}-dr-${var.environment}"
  kubernetes_version  = var.aks_kubernetes_version

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.secondary_aks_nodes[0].id

    enable_auto_scaling = var.aks_enable_auto_scaling
    min_count           = var.aks_min_node_count
    max_count           = var.aks_max_node_count

    tags = merge(var.tags, {
      Name = "${var.project_name}-nodepool-secondary-${var.environment}"
    })
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_secondary[0].id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_secondary[0].client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_secondary[0].principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_secondary[0].id
  }

  network_profile {
    network_plugin     = var.aks_network_plugin
    network_policy     = "azure"
    service_cidr       = var.aks_service_cidr
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    dns_service_ip     = var.aks_dns_service_ip
  }

  role_based_access_control_enabled = var.aks_enable_rbac

  addon_profile {
    oms_agent {
      enabled                    = var.aks_enable_monitoring
      log_analytics_workspace_id = azurerm_log_analytics_workspace.secondary[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-aks-dr-${var.environment}"
  })
}

# Secondary region resources
resource "azurerm_virtual_network" "secondary" {
  count               = var.enable_secondary_region ? 1 : 0
  name                = "${var.project_name}-vnet-dr-${var.environment}"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.secondary[0].location
  resource_group_name = azurerm_resource_group.secondary[0].name

  tags = merge(var.tags, {
    Name = "${var.project_name}-vnet-dr-${var.environment}"
  })
}

resource "azurerm_subnet" "secondary_aks_nodes" {
  count                = var.enable_secondary_region ? 1 : 0
  name                 = "${var.project_name}-subnet-nodes-dr-${var.environment}"
  resource_group_name  = azurerm_resource_group.secondary[0].name
  virtual_network_name = azurerm_virtual_network.secondary[0].name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_user_assigned_identity" "aks_secondary" {
  count               = var.enable_secondary_region ? 1 : 0
  name                = "${var.project_name}-aks-identity-dr-${var.environment}"
  resource_group_name = azurerm_resource_group.secondary[0].name
  location            = azurerm_resource_group.secondary[0].location
}

resource "azurerm_user_assigned_identity" "kubelet_secondary" {
  count               = var.enable_secondary_region ? 1 : 0
  name                = "${var.project_name}-kubelet-identity-dr-${var.environment}"
  resource_group_name = azurerm_resource_group.secondary[0].name
  location            = azurerm_resource_group.secondary[0].location
}

resource "azurerm_log_analytics_workspace" "secondary" {
  count               = var.enable_secondary_region ? 1 : 0
  name                = "${var.project_name}-logs-dr-${var.environment}"
  location            = azurerm_resource_group.secondary[0].location
  resource_group_name = azurerm_resource_group.secondary[0].name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
}

# Kubeconfig file generation
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.main.kube_config_raw
  filename = "${path.module}/.kube/config"

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Configure kubectl context
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}
