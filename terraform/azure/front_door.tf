# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.project_name}-afd-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.front_door_sku

  tags = merge(var.tags, {
    Name = "${var.project_name}-afd-${var.environment}"
  })
}

# Web Application Firewall Policy
resource "azurerm_cdn_frontdoor_waf_policy" "main" {
  count = var.front_door_enable_waf ? 1 : 0

  name                              = "${replace(var.project_name, "-", "")}waf${var.environment}"
  resource_group_name               = azurerm_resource_group.main.name
  sku_name                          = var.front_door_sku
  enabled                           = true
  mode                              = var.front_door_waf_policy_mode
  redirect_url                      = "https://example.com/blocked"
  custom_block_response_status_code = 403

  custom_rule {
    name           = "BlockGeoRestricted"
    enabled        = true
    priority       = 1
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 300
    type           = "RateLimitRule"
    action         = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IpMatch"
      negation_condition = false
      match_values = [
        "192.168.1.0/24"  # Example: block specific IPs
      ]
    }
  }

  # Common rules set (OWASP)
  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"

    override {
      rule_group_name = "PROTOCOL-ATTACK"
      rule_id = "PL3008"
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-waf-${var.environment}"
  })
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${replace(var.project_name, "-", "")}-afd-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-afd-endpoint-${var.environment}"
  })
}

# Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "aks" {
  name                     = "${var.project_name}-og-aks-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
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

# Front Door Origin for AKS service
resource "azurerm_cdn_frontdoor_origin" "aks" {
  name                     = "${var.project_name}-origin-aks-${var.environment}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks.id
  enabled                  = true
  host_name                = var.cloudfront_api_domain_name != "" ? var.cloudfront_api_domain_name : "api.example.com"
  http_port                = 80
  https_port               = 443
  origin_host_header       = var.cloudfront_api_domain_name != "" ? var.cloudfront_api_domain_name : "api.example.com"
  priority                 = 1
  weight                   = 1

  certificate_name_check_enabled = true
}

# Route for API
resource "azurerm_cdn_frontdoor_route" "api" {
  name                          = "${var.project_name}-route-api-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.aks.id]
  enabled                       = true

  forwarded_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match     = ["/api/*"]
  supported_protocols   = ["Http", "Https"]

  cache {
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "text/html", "text/plain"]
    query_string_caching_behavior = "UseQueryString"
  }

  depends_on = [azurerm_cdn_frontdoor_origin.aks]
}

# Route for health checks
resource "azurerm_cdn_frontdoor_route" "health" {
  name                          = "${var.project_name}-route-health-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.aks.id]
  enabled                       = true

  forwarded_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match     = ["/health"]
  supported_protocols   = ["Http", "Https"]

  cache {
    compression_enabled           = false
    query_string_caching_behavior = "IgnoreQueryString"
  }

  depends_on = [azurerm_cdn_frontdoor_origin.aks]
}

# Route for root
resource "azurerm_cdn_frontdoor_route" "root" {
  name                          = "${var.project_name}-route-root-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.aks.id]
  enabled                       = true

  forwarded_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match     = ["/*"]
  supported_protocols   = ["Http", "Https"]

  cache {
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "text/html", "text/javascript"]
    query_string_caching_behavior = "IgnoreQueryString"
  }

  depends_on = [azurerm_cdn_frontdoor_origin.aks]
}

# Custom domain (if provided)
resource "azurerm_cdn_frontdoor_custom_domain" "main" {
  count = var.front_door_custom_domain_name != "" ? 1 : 0

  name                     = replace(var.front_door_custom_domain_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  dns_zone_id              = azurerm_dns_zone.main[0].id
  host_name                = var.front_door_custom_domain_name

  tls {
    certificate_type    = var.front_door_certificate_type
    minimum_tls_version = "TLS12"
  }

  depends_on = [azurerm_dns_cname_record.afd]
}

# Associate WAF policy with Front Door
resource "azurerm_cdn_frontdoor_rule_set" "main" {
  count = var.front_door_enable_waf ? 1 : 0

  name                     = "${var.project_name}-rs-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Front Door Rule
resource "azurerm_cdn_frontdoor_rule" "security_headers" {
  name                     = "${var.project_name}-rule-headers-${var.environment}"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.main[0].id
  order                    = 1
  behavior_on_match        = "Continue"

  actions_route_override_action {
    cache_behavior  = "BypassCache"
    cache_duration  = "00:00:00"
  }

  actions_response_header_action {
    header_action_type = "Append"
    header_name        = "X-Content-Type-Options"
    value              = "nosniff"
  }

  actions_response_header_action {
    header_action_type = "Append"
    header_name        = "X-Frame-Options"
    value              = "DENY"
  }

  actions_response_header_action {
    header_action_type = "Append"
    header_name        = "X-XSS-Protection"
    value              = "1; mode=block"
  }
}

# DNS Zone for custom domain
resource "azurerm_dns_zone" "main" {
  count               = var.front_door_custom_domain_name != "" ? 1 : 0
  name                = var.front_door_custom_domain_name
  resource_group_name = azurerm_resource_group.main.name
}

# DNS CNAME record
resource "azurerm_dns_cname_record" "afd" {
  count               = var.front_door_custom_domain_name != "" ? 1 : 0
  name                = "@"
  zone_name           = azurerm_dns_zone.main[0].name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.main.host_name
}

# Diagnostic settings for Front Door
resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name               = "${var.project_name}-afd-diag-${var.environment}"
  target_resource_id = azurerm_cdn_frontdoor_profile.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }

  metric {
    category = "AllMetrics"
  }
}
