# Terraform Variables Example
# Copy this to terraform.tfvars and modify values as needed
# Uncomment and change values to override defaults

# AWS Configuration
# aws_region = "us-east-1"
# environment = "prod"
# project_name = "weather-tracker"

# VPC Configuration
# vpc_cidr = "10.0.0.0/16"
# availability_zones = 2
# enable_nat_gateway = true
# enable_vpn_gateway = false
# enable_private_dns = true

# EKS Configuration
# eks_version = "1.28"
# eks_endpoint_private_access = true
# eks_endpoint_public_access = true
# eks_public_access_cidrs = ["0.0.0.0/0"]  # Restrict this in production!
# eks_enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Node Group Configuration
# node_group_desired_size = 3
# node_group_min_size = 1
# node_group_max_size = 10
# node_instance_types = ["t3.medium", "t3.large"]
# node_disk_size = 50
# node_group_capacity_type = "ON_DEMAND"  # or "SPOT" for cost optimization

# Monitoring & Logging
# log_retention_days = 7
# enable_cluster_autoscaling = true
# enable_pod_security_policy = false
# enable_high_availability = true

# Tags
# tags = {
#   Managed    = "Terraform"
#   CostCenter = "engineering"
#   Owner      = "platform-team"
# }

# ============================================================================
# RDS PostgreSQL Configuration
# ============================================================================
# rds_instance_class = "db.t4g.medium"
# rds_allocated_storage = 100
# rds_storage_type = "gp3"
# rds_iops = 3000
# rds_postgres_version = "15.4"
# rds_database_name = "weatherdb"
# rds_master_username = "postgres"
# rds_master_password = "SecurePassword123!"  # Use Secrets Manager in production!
# rds_multi_az = true
# rds_backup_retention_days = 30
# rds_backup_window = "03:00-04:00"
# rds_maintenance_window = "sun:04:00-sun:05:00"
# rds_max_connections = 100
# rds_log_min_duration = 1000
# rds_allowed_cidr_blocks = ["10.0.0.0/16"]
# enable_rds_enhanced_monitoring = true
# enable_rds_performance_insights = true
# rds_performance_insights_retention = 7

# ============================================================================
# S3 Configuration
# ============================================================================
# s3_cors_allowed_origins = ["https://yourdomain.com", "https://www.yourdomain.com"]
# s3_size_alarm_threshold = 107374182400  # 100GB in bytes
# s3_object_count_alarm_threshold = 1000000  # 1 million objects
# enable_s3_replication = false
# s3_replication_destination_arn = ""

# ============================================================================
# CloudFront Configuration
# ============================================================================
# cloudfront_default_root_object = "index.html"
# cloudfront_api_domain_name = "api-lb-1234567890.us-east-1.elb.amazonaws.com"
# cloudfront_price_class = "PriceClass_100"  # All, 100, or 200
# cloudfront_geo_restriction_type = "none"  # or "whitelist", "blacklist"
# cloudfront_geo_restriction_locations = []  # e.g., ["US", "CA", "GB"]
# cloudfront_use_default_certificate = true
# cloudfront_acm_certificate_arn = ""  # e.g., arn:aws:acm:us-east-1:xxx:certificate/xxx
# cloudfront_waf_arn = ""  # e.g., arn:aws:wafv2:us-east-1:xxx:global/webacl/xxx

# ============================================================================
# Route53 Configuration
# ============================================================================
# route53_domain_name = "yourdomain.com"
# route53_create_hosted_zone = true
# route53_enable_secondary = false
# route53_secondary_cloudfront_domain = ""  # e.g., d-xxxxxxxx.cloudfront.net
# route53_enable_api_failover = false
# route53_enable_traffic_policy = false
# route53_enable_calculated_health_check = true
# route53_enable_resolver_endpoint = false
# route53_enable_resolver_rule = false
# route53_resolver_domain_name = ""  # e.g., "internal.company.local"
# route53_resolver_target_ip_1 = ""  # e.g., "192.168.1.1"
# route53_resolver_target_ip_2 = ""  # e.g., "192.168.1.2"

