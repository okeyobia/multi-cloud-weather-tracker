# Traffic Manager Profile
resource "azurerm_traffic_manager_profile" "main" {
  name                   = var.traffic_manager_profile_name != "" ? var.traffic_manager_profile_name : "${var.project_name}-tm-${var.environment}"
  resource_group_name    = azurerm_resource_group.main.name
  traffic_routing_method = var.traffic_manager_routing_method
  dns_config {
    relative_name = var.traffic_manager_profile_name != "" ? var.traffic_manager_profile_name : "${var.project_name}-tm-${var.environment}"
    ttl           = 60
  }

  monitor_config {
    protocol                     = var.traffic_manager_protocol
    port                         = var.traffic_manager_port
    path                         = var.traffic_manager_path
    interval_in_seconds          = var.traffic_manager_interval
    tolerated_number_of_failures = var.traffic_manager_tolerated_failures
    timeout_in_seconds           = var.traffic_manager_timeout
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tm-${var.environment}"
  })
}

# Primary endpoint (Front Door)
resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "${var.project_name}-tm-ep-primary-${var.environment}"
  profile_name       = azurerm_traffic_manager_profile.main.name
  resource_group_name = azurerm_resource_group.main.name
  type               = "azureEndpoints"
  enabled            = true
  priority           = 1
  target             = azurerm_cdn_frontdoor_endpoint.main.host_name
  
  custom_header {
    name  = "X-Traffic-Manager"
    value = "primary"
  }
}

# Secondary endpoint (if enabled)
resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
  count = var.enable_secondary_region ? 1 : 0

  name               = "${var.project_name}-tm-ep-secondary-${var.environment}"
  profile_name       = azurerm_traffic_manager_profile.main.name
  resource_group_name = azurerm_resource_group.main.name
  type               = "azureEndpoints"
  enabled            = true
  priority           = 2
  target             = azurerm_cdn_frontdoor_endpoint.secondary[0].host_name
  
  custom_header {
    name  = "X-Traffic-Manager"
    value = "secondary"
  }

  depends_on = [azurerm_cdn_frontdoor_endpoint.secondary]
}

# Secondary Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "secondary" {
  count = var.enable_secondary_region ? 1 : 0

  name                = "${var.project_name}-afd-dr-${var.environment}"
  resource_group_name = azurerm_resource_group.secondary[0].name
  sku_name            = var.front_door_sku

  tags = merge(var.tags, {
    Name = "${var.project_name}-afd-dr-${var.environment}"
  })
}

# Secondary Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "secondary" {
  count = var.enable_secondary_region ? 1 : 0

  name                     = "${replace(var.project_name, "-", "")}-afd-dr-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.secondary[0].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-afd-dr-endpoint-${var.environment}"
  })
}

# Secondary Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "secondary_aks" {
  count = var.enable_secondary_region ? 1 : 0

  name                     = "${var.project_name}-og-aks-dr-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.secondary[0].id
  session_affinity_enabled = false

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }

  health_probe {
    interval_in_seconds = 100
    path                = "/health"
    protocol            = "Https"
    request_type        = "GET"
  }
}

# Secondary Origin
resource "azurerm_cdn_frontdoor_origin" "secondary_aks" {
  count = var.enable_secondary_region ? 1 : 0

  name                          = "${var.project_name}-origin-aks-dr-${var.environment}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.secondary_aks[0].id
  enabled                       = true
  host_name                     = "${azurerm_kubernetes_cluster.secondary[0].name}.eastus2.azmk8s.io"  # Example, adjust region
  https_port                    = 443
  priority                      = 1
  weight                        = 1

  certificate_name_check_enabled = true
}

# Secondary routes
resource "azurerm_cdn_frontdoor_route" "secondary_api" {
  count = var.enable_secondary_region ? 1 : 0

  name                          = "${var.project_name}-route-api-dr-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.secondary[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.secondary_aks[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.secondary_aks[0].id]
  enabled                       = true

  forwarded_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match     = ["/api/*"]
  supported_protocols   = ["Http", "Https"]

  cache {
    compression_enabled           = true
    content_types_to_compress     = ["application/json"]
    query_string_caching_behavior = "UseQueryString"
  }

  depends_on = [azurerm_cdn_frontdoor_origin.secondary_aks]
}

# Monitoring alert for Traffic Manager
resource "azurerm_monitor_metric_alert" "traffic_manager_health" {
  name                = "${var.project_name}-tm-health-alert-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_traffic_manager_profile.main.id]
  frequency           = "PT1M"
  window_size         = "PT5M"
  severity            = 2
  enabled             = true
  description         = "Alert when Traffic Manager endpoint is degraded"

  criteria {
    metric_name       = "ProbeAgentCurrentEndpointStateByProfileResourceId"
    metric_namespace  = "Microsoft.Network/trafficManagerProfiles"
    operator          = "LessThan"
    threshold         = 1
    aggregation       = "Total"
    statistic         = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts[0].id
  }
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "alerts" {
  count               = 1
  name                = "${var.project_name}-action-group-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-action-group-${var.environment}"
  })
}

# Diagnostic settings for Traffic Manager
resource "azurerm_monitor_diagnostic_setting" "traffic_manager" {
  name               = "${var.project_name}-tm-diag-${var.environment}"
  target_resource_id = azurerm_traffic_manager_profile.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
  }
}
