# CloudFront Distribution for content delivery and API acceleration
# Serves static content from S3 and proxies API requests with caching and security

# CloudFront Origin Access Identity (for S3)
# Already defined in s3.tf

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.cloudfront_default_root_object
  comment             = "${var.project_name} distribution - ${var.environment}"

  # S3 origin for static content
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  # API origin (load balancer or ALB) - conditional based on API domain name
  dynamic "origin" {
    for_each = var.cloudfront_api_domain_name != "" ? [1] : []
    content {
      domain_name = var.cloudfront_api_domain_name
      origin_id   = "APIOrigin"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      custom_header {
        name  = "X-Custom-Header"
        value = "WeatherTracker"
      }
    }
  }

  # Cache behavior for API - only if API domain is configured
  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_api_domain_name != "" ? [1] : []
    content {
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      path_pattern = "/api/*"

      target_origin_id = "APIOrigin"

      forwarded_values {
        query_string = true
        headers      = ["Authorization", "Host", "Content-Type", "Accept"]

        cookies {
          forward = "all"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }

  # Cache behavior for health endpoint - only if API domain is configured
  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_api_domain_name != "" ? [1] : []
    content {
      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]

      path_pattern = "/health"

      target_origin_id = "APIOrigin"

      forwarded_values {
        query_string = false

        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "allow-all"
      compress               = true
      min_ttl                = 0
      default_ttl            = 60     # Cache health checks for 1 minute
      max_ttl                = 300    # Max 5 minutes
    }
  }

  # Cache behavior for static content with aggressive caching
  ordered_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    path_pattern = "/assets/*"

    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 86400   # 1 day
    max_ttl                = 31536000  # 1 year
  }

  # Default cache behavior for S3 content
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600     # 1 hour
    max_ttl                = 86400    # 1 day
  }

  # Price class (affects performance and cost)
  price_class = var.cloudfront_price_class

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geo_restriction_type
      locations        = var.cloudfront_geo_restriction_locations
    }
  }

  # SSL/TLS certificate
  viewer_certificate {
    cloudfront_default_certificate = var.cloudfront_use_default_certificate

    # Use custom certificate if provided
    acm_certificate_arn            = var.cloudfront_acm_certificate_arn != "" ? var.cloudfront_acm_certificate_arn : null
    ssl_support_method             = var.cloudfront_acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.cloudfront_acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  # Web ACL (for AWS WAF protection)
  web_acl_id = var.cloudfront_waf_arn != "" ? var.cloudfront_waf_arn : null

  # Logging
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log.bucket_regional_domain_name
    prefix          = "cloudfront-logs/"
  }

  # Custom error responses
  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 300
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 300
    response_code         = 404
    response_page_path    = "/404.html"
  }

  # HTTP/2 and HTTP/3 support
  http_version = "http2and3"

  tags = {
    Name = "${var.project_name}-cloudfront-${var.environment}"
  }
}

# CloudFront Distribution Record in Route53 (created in route53.tf)
# This will be the primary distribution with failover

# CloudFront Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "cloudfront" {
  dashboard_name = "${var.project_name}-cloudfront-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", { stat = "Sum" }],
            [".", "BytesDownloaded", { stat = "Sum" }],
            [".", "BytesUploaded", { stat = "Sum" }],
            [".", "4xxErrorRate", { stat = "Average" }],
            [".", "5xxErrorRate", { stat = "Average" }],
            [".", "CacheHitRate", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "CloudFront Performance"
        }
      }
    ]
  })
}

# CloudWatch Alarms for CloudFront
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "${var.project_name}-cf-4xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Alert on high 4xx error rate"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "${var.project_name}-cf-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert on high 5xx error rate"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_hit_rate" {
  alarm_name          = "${var.project_name}-cf-cache-hit-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "3600"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "Alert if cache hit rate drops below 50%"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }
}
