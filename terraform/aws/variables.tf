variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)"
  }
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
    condition     = length(var.project_name) <= 20
    error_message = "Project name must be 20 characters or less"
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

variable "availability_zones" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zones >= 2 && var.availability_zones <= 3
    error_message = "Must use 2 or 3 availability zones"
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_private_dns" {
  description = "Enable private DNS"
  type        = bool
  default     = true
}

# EKS Configuration
variable "eks_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[8-9]|3[0-9])$", var.eks_version))
    error_message = "EKS version must be 1.28 or later"
  }
}

variable "eks_endpoint_private_access" {
  description = "Enable private API access"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Enable public API access"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition     = alltrue([for log_type in var.eks_enabled_cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)])
    error_message = "Invalid log type specified"
  }
}

# Node Group Configuration
variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.node_group_desired_size >= 1 && var.node_group_desired_size <= 100
    error_message = "Desired size must be between 1 and 100"
  }
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_group_min_size >= 1
    error_message = "Minimum size must be at least 1"
  }
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10

  validation {
    condition     = var.node_group_max_size >= 1
    error_message = "Maximum size must be at least 1"
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "Must specify at least one instance type"
  }
}

variable "node_disk_size" {
  description = "Root volume size in GB for worker nodes"
  type        = number
  default     = 50

  validation {
    condition     = var.node_disk_size >= 20 && var.node_disk_size <= 1000
    error_message = "Disk size must be between 20 and 1000 GB"
  }
}

variable "node_group_capacity_type" {
  description = "Capacity type for node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group_capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT"
  }
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    Managed = "Terraform"
  }
}

# CloudWatch Logs
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention value"
  }
}

# Enable monitoring and control plane logging
variable "enable_cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy"
  type        = bool
  default     = false
}

# High Availability
variable "enable_high_availability" {
  description = "Enable high availability configuration"
  type        = bool
  default     = true
}

# RDS PostgreSQL Configuration
variable "rds_instance_class" {
  description = "Instance class for RDS database"
  type        = string
  default     = "db.t4g.medium"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.rds_instance_class))
    error_message = "Invalid RDS instance class format"
  }
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 100

  validation {
    condition     = var.rds_allocated_storage >= 20 && var.rds_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB"
  }
}

variable "rds_storage_type" {
  description = "Storage type for RDS (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.rds_storage_type)
    error_message = "Storage type must be one of: gp2, gp3, io1, io2"
  }
}

variable "rds_iops" {
  description = "IOPS for RDS (for gp3, io1, io2)"
  type        = number
  default     = 3000

  validation {
    condition     = var.rds_iops >= 1000 && var.rds_iops <= 64000
    error_message = "IOPS must be between 1000 and 64000"
  }
}

variable "rds_postgres_version" {
  description = "PostgreSQL version for RDS"
  type        = string
  default     = "15.4"
}

variable "rds_database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "weatherdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.rds_database_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores"
  }
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "rds_master_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.rds_master_password) >= 8
    error_message = "Password must be at least 8 characters"
  }
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "rds_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30

  validation {
    condition     = var.rds_backup_retention_days >= 1 && var.rds_backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days"
  }
}

variable "rds_backup_window" {
  description = "Backup window for RDS (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Maintenance window for RDS (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_parameter_family" {
  description = "DB parameter family"
  type        = string
  default     = "postgres15"
}

variable "rds_max_connections" {
  description = "Maximum database connections"
  type        = number
  default     = 100

  validation {
    condition     = var.rds_max_connections >= 20 && var.rds_max_connections <= 10000
    error_message = "Max connections must be between 20 and 10000"
  }
}

variable "rds_log_min_duration" {
  description = "Log queries longer than this (milliseconds, -1 to disable)"
  type        = number
  default     = 1000
}

variable "rds_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "enable_rds_enhanced_monitoring" {
  description = "Enable enhanced monitoring for RDS"
  type        = bool
  default     = true
}

variable "enable_rds_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = true
}

variable "rds_performance_insights_retention" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 31, 62, 93, 124, 155, 186, 217, 248, 279, 310, 341, 372, 403, 434, 465, 496, 527, 558, 589, 620, 651, 682, 713, 744, 775], var.rds_performance_insights_retention)
    error_message = "Performance Insights retention must be a valid value (7 or 31-775 in 31-day increments)"
  }
}

# S3 Configuration
variable "s3_cors_allowed_origins" {
  description = "CORS allowed origins for S3"
  type        = list(string)
  default     = ["*"]
}

variable "s3_size_alarm_threshold" {
  description = "S3 bucket size alarm threshold in bytes"
  type        = number
  default     = 107374182400  # 100GB
}

variable "s3_object_count_alarm_threshold" {
  description = "S3 object count alarm threshold"
  type        = number
  default     = 1000000  # 1 million objects
}

variable "enable_s3_replication" {
  description = "Enable S3 bucket replication"
  type        = bool
  default     = false
}

variable "s3_replication_destination_arn" {
  description = "S3 replication destination bucket ARN"
  type        = string
  default     = ""
}

# CloudFront Configuration
variable "cloudfront_default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "cloudfront_api_domain_name" {
  description = "Domain name for API origin (ALB or NLB)"
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "Price class for CloudFront (PriceClass_All, PriceClass_100, PriceClass_200)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_100", "PriceClass_200"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_100, PriceClass_200"
  }
}

variable "cloudfront_geo_restriction_type" {
  description = "Type of geo restriction (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.cloudfront_geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist"
  }
}

variable "cloudfront_geo_restriction_locations" {
  description = "List of countries/locations for geo restriction (ISO 3166-1-alpha-2 codes)"
  type        = list(string)
  default     = []
}

variable "cloudfront_use_default_certificate" {
  description = "Use CloudFront default certificate (vs custom ACM cert)"
  type        = bool
  default     = true
}

variable "cloudfront_acm_certificate_arn" {
  description = "ARN of ACM certificate for CloudFront"
  type        = string
  default     = ""
}

variable "cloudfront_waf_arn" {
  description = "ARN of WAF ACL for CloudFront protection"
  type        = string
  default     = ""
}

# Route53 Configuration
variable "route53_domain_name" {
  description = "Domain name for Route53"
  type        = string
  default     = ""
}

variable "route53_create_hosted_zone" {
  description = "Create a new Route53 hosted zone"
  type        = bool
  default     = false
}

variable "route53_enable_secondary" {
  description = "Enable secondary failover record"
  type        = bool
  default     = false
}

variable "route53_secondary_cloudfront_domain" {
  description = "Secondary CloudFront domain for failover"
  type        = string
  default     = ""
}

variable "route53_enable_api_failover" {
  description = "Enable API failover records"
  type        = bool
  default     = false
}

variable "route53_enable_traffic_policy" {
  description = "Enable Route53 traffic policy"
  type        = bool
  default     = false
}

variable "route53_enable_calculated_health_check" {
  description = "Enable calculated health check"
  type        = bool
  default     = true
}

variable "route53_enable_resolver_endpoint" {
  description = "Enable Route53 Resolver endpoint for hybrid DNS"
  type        = bool
  default     = false
}

variable "route53_enable_resolver_rule" {
  description = "Enable Route53 Resolver forwarding rule"
  type        = bool
  default     = false
}

variable "route53_resolver_domain_name" {
  description = "Domain name for Route53 Resolver forwarding"
  type        = string
  default     = ""
}

variable "route53_resolver_target_ip_1" {
  description = "First target IP for Route53 Resolver"
  type        = string
  default     = ""
}

variable "route53_resolver_target_ip_2" {
  description = "Second target IP for Route53 Resolver"
  type        = string
  default     = ""
}
