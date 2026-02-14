# Route53 DNS with failover and health checks
# Primary CloudFront distribution with automatic failover to secondary

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  count = var.route53_create_hosted_zone ? 1 : 0
  name  = var.route53_domain_name

  tags = {
    Name = "${var.project_name}-zone-${var.environment}"
  }
}

# Health Check for Primary CloudFront
resource "aws_route53_health_check" "primary_cloudfront" {
  fqdn              = aws_cloudfront_distribution.main.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  measure_latency = true
  enable_sni      = true

  tags = {
    Name = "${var.project_name}-hc-primary-cf-${var.environment}"
  }
}

# Health Check for Secondary CloudFront (if using multi-region)
resource "aws_route53_health_check" "secondary_cloudfront" {
  count = var.route53_enable_secondary ? 1 : 0

  fqdn              = var.route53_secondary_cloudfront_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  measure_latency = true
  enable_sni      = true

  tags = {
    Name = "${var.project_name}-hc-secondary-cf-${var.environment}"
  }
}

# Health Check for API Load Balancer
resource "aws_route53_health_check" "api_lb" {
  count = var.route53_enable_api_failover ? 1 : 0

  fqdn              = var.cloudfront_api_domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  measure_latency = true
  enable_sni      = true

  tags = {
    Name = "${var.project_name}-hc-api-${var.environment}"
  }
}

# CloudWatch Alarm for Primary Health Check
resource "aws_cloudwatch_metric_alarm" "route53_primary_health" {
  alarm_name          = "${var.project_name}-route53-primary-health-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert when primary health check fails"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary_cloudfront.id
  }
}

# Route53 A Record - Primary (Failover to Secondary)
resource "aws_route53_record" "main_primary" {
  count   = var.route53_create_hosted_zone ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.route53_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }

  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary_cloudfront.id
}

# Route53 A Record - Secondary (for failover)
resource "aws_route53_record" "main_secondary" {
  count   = var.route53_create_hosted_zone && var.route53_enable_secondary ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.route53_domain_name
  type    = "A"

  alias {
    name                   = var.route53_secondary_cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront global zone ID
    evaluate_target_health = true
  }

  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = var.route53_enable_secondary ? aws_route53_health_check.secondary_cloudfront[0].id : null
}

# Route53 Records for API (with weighted routing for traffic shifting)
resource "aws_route53_record" "api_primary" {
  count   = var.route53_create_hosted_zone && var.route53_enable_api_failover ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "api.${var.route53_domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_api_domain_name
    zone_id                = "Z35SXDOTRQ7X7K"  # Generic ALB/ELB zone ID (verify with your region)
    evaluate_target_health = true
  }

  set_identifier = "api-primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.api_lb[0].id
}

# Route53 CNAME Records for subdomains
resource "aws_route53_record" "www" {
  count   = var.route53_create_hosted_zone ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "www.${var.route53_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_route53_record.main_primary[0].fqdn]
}

# Route53 Records for application endpoints
resource "aws_route53_record" "weather" {
  count   = var.route53_create_hosted_zone ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "weather.${var.route53_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.main.domain_name]
}

# Route53 Traffic Policy (for complex routing)
resource "aws_route53_traffic_policy" "main" {
  count = var.route53_enable_traffic_policy ? 1 : 0
  name  = "${var.project_name}-policy-${var.environment}"

  document = jsonencode({
    AWSPolicyFormatVersion = "2015-10-31"
    RecordType             = "A"
    Endpoints = {
      "endpoint-primary" = {
        Type   = "CloudFront"
        Domain = aws_cloudfront_distribution.main.domain_name
        HealthCheck = {
          Type              = "HTTPS"
          ResourcePath      = "/health"
          FullyQualifiedDomainName = aws_cloudfront_distribution.main.domain_name
          Port              = 443
          RequestInterval   = 30
          FailureThreshold  = 3
        }
      },
      "endpoint-secondary" = var.route53_enable_secondary ? {
        Type   = "CloudFront"
        Domain = var.route53_secondary_cloudfront_domain
        HealthCheck = {
          Type              = "HTTPS"
          ResourcePath      = "/health"
          FullyQualifiedDomainName = var.route53_secondary_cloudfront_domain
          Port              = 443
          RequestInterval   = 30
          FailureThreshold  = 3
        }
      } : null
    }
  })
}

# Route53 Traffic Policy Instance (apply policy to domain)
resource "aws_route53_traffic_policy_instance" "main" {
  count                   = var.route53_enable_traffic_policy ? 1 : 0
  hosted_zone_id          = aws_route53_zone.main[0].zone_id
  traffic_policy_id       = aws_route53_traffic_policy.main[0].id
  traffic_policy_version  = aws_route53_traffic_policy.main[0].version
  name                    = var.route53_domain_name
  ttl                     = 300
}

# Route53 Query Logging
resource "aws_cloudwatch_log_group" "route53" {
  name              = "/aws/route53/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-route53-logs-${var.environment}"
  }
}



# Route53 Health Check for Overall Domain
resource "aws_route53_health_check" "calculated" {
  count                        = var.route53_enable_calculated_health_check ? 1 : 0
  type                         = "CALCULATED"
  child_healthchecks           = [aws_route53_health_check.primary_cloudfront.id]

  tags = {
    Name = "${var.project_name}-health-calculated-${var.environment}"
  }
}

# Monitoring Data Source for existing hosted zone (if not creating)
data "aws_route53_zone" "main" {
  count = !var.route53_create_hosted_zone && var.route53_domain_name != "" ? 1 : 0
  name  = var.route53_domain_name
}

# Route53 Resolver Endpoint (for hybrid DNS resolution)
resource "aws_route53_resolver_endpoint" "main" {
  count              = var.route53_enable_resolver_endpoint ? 1 : 0
  name               = "${var.project_name}-resolver-${var.environment}"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.route53_resolver[count.index].id]

  ip_address {
    subnet_id = aws_subnet.private[0].id
  }

  ip_address {
    subnet_id = aws_subnet.private[1].id
  }

  tags = {
    Name = "${var.project_name}-resolver-${var.environment}"
  }
}

# Security Group for Route53 Resolver
resource "aws_security_group" "route53_resolver" {
  count       = var.route53_enable_resolver_endpoint ? 1 : 0
  name        = "${var.project_name}-resolver-sg-${var.environment}"
  description = "Security group for Route53 Resolver"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS TCP"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS UDP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-resolver-sg-${var.environment}"
  }
}

# Route53 Resolver Rule for hybrid DNS
resource "aws_route53_resolver_rule" "main" {
  count            = var.route53_enable_resolver_rule && var.route53_enable_resolver_endpoint ? 1 : 0
  name             = "${var.project_name}-resolver-rule-${var.environment}"
  domain_name      = var.route53_resolver_domain_name
  rule_type        = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.main[0].id

  target_ip {
    ip = var.route53_resolver_target_ip_1
  }

  target_ip {
    ip = var.route53_resolver_target_ip_2
  }

  tags = {
    Name = "${var.project_name}-resolver-rule-${var.environment}"
  }
}

# Route53 Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "route53" {
  dashboard_name = "${var.project_name}-route53-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", { stat = "Minimum" }],
            ["AWS/Route53", "HealthCheckPercentageHealthy", { stat = "Average" }],
            ["AWS/Route53", "ConnectionTime", { stat = "Average" }],
            ["AWS/Route53", "TimeToFirstByte", { stat = "Average" }],
            ["AWS/Route53", "SSLHandshakeTime", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Route53 Health & Performance"
        }
      }
    ]
  })
}
