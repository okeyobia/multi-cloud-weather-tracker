# EKS Cluster Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for your EKS API server"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.main.version
}

output "eks_cluster_certificate_authority" {
  description = "Certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_platform_version" {
  description = "Platform version of the cluster"
  value       = aws_eks_cluster.main.platform_version
}

# EKS Node Group Outputs
output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "eks_node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.main.status
}

output "eks_node_group_resources" {
  description = "Resources of the EKS node group"
  value       = aws_eks_node_group.main.resources
}

# IAM Role Outputs
output "eks_cluster_iam_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_iam_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node.arn
}

# OIDC Provider Output (for IRSA)
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Security Group Outputs
output "eks_control_plane_security_group_id" {
  description = "Security group ID for EKS control plane"
  value       = aws_security_group.eks_control_plane.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

# CloudWatch Log Group Output
output "eks_cluster_log_group_name" {
  description = "CloudWatch log group name for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

# Cluster Autoscaler IAM Role Output
output "cluster_autoscaler_role_arn" {
  description = "ARN of Cluster Autoscaler IAM role (for IRSA)"
  value       = var.enable_cluster_autoscaling ? aws_iam_role.cluster_autoscaler[0].arn : null
}

# Connection information for kubectl
output "configure_kubectl" {
  description = "Command to configure kubectl with EKS cluster credentials"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name} --profile default"
}

# RDS PostgreSQL Outputs
output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "rds_endpoint" {
  description = "RDS database endpoint (hostname:port)"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS database address (hostname only)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS initial database name"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.main.username
}

output "rds_multi_az" {
  description = "RDS Multi-AZ status"
  value       = aws_db_instance.main.multi_az
}

output "rds_storage_type" {
  description = "RDS storage type"
  value       = aws_db_instance.main.storage_type
}

output "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  value       = aws_db_instance.main.allocated_storage
}

output "rds_engine_version" {
  description = "RDS PostgreSQL engine version"
  value       = aws_db_instance.main.engine_version
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "rds_secret_arn" {
  description = "ARN of Secrets Manager secret containing RDS credentials"
  value       = aws_secretsmanager_secret.rds_password.arn
}

output "rds_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.main.username}:PASSWORD@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "s3_log_bucket_id" {
  description = "S3 logging bucket ID"
  value       = aws_s3_bucket.log.id
}

output "s3_cloudfront_oai_iam_arn" {
  description = "CloudFront OAI IAM ARN for S3 policy"
  value       = aws_cloudfront_origin_access_identity.main.iam_arn
}

# CloudFront Distribution Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_oai_cloudfront_access_identity_path" {
  description = "CloudFront OAI access identity path"
  value       = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
}

# Route53 Hosted Zone Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.route53_create_hosted_zone ? aws_route53_zone.main[0].zone_id : null
}

output "route53_zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = var.route53_create_hosted_zone ? aws_route53_zone.main[0].arn : null
}

output "route53_zone_nameservers" {
  description = "Route53 hosted zone nameservers"
  value       = var.route53_create_hosted_zone ? aws_route53_zone.main[0].name_servers : null
}

# Route53 Health Check Outputs
output "route53_primary_health_check_id" {
  description = "Route53 primary health check ID"
  value       = aws_route53_health_check.primary_cloudfront.id
}

output "route53_secondary_health_check_id" {
  description = "Route53 secondary health check ID"
  value       = var.route53_enable_secondary ? aws_route53_health_check.secondary_cloudfront[0].id : null
}

# Route53 A Record Outputs
output "route53_primary_record_fqdn" {
  description = "Primary Route53 A record FQDN"
  value       = var.route53_create_hosted_zone ? aws_route53_record.main_primary[0].fqdn : null
}

output "route53_secondary_record_fqdn" {
  description = "Secondary Route53 A record FQDN (failover)"
  value       = var.route53_create_hosted_zone && var.route53_enable_secondary ? aws_route53_record.main_secondary[0].fqdn : null
}

output "route53_api_record_fqdn" {
  description = "Route53 API A record FQDN"
  value       = var.route53_create_hosted_zone && var.route53_enable_api_failover ? aws_route53_record.api_primary[0].fqdn : null
}

# AWS Infrastructure Summary
output "aws_deployment_summary" {
  description = "Summary of AWS deployed infrastructure"
  value = {
    cluster_name            = aws_eks_cluster.main.name
    cluster_endpoint        = aws_eks_cluster.main.endpoint
    cluster_version         = aws_eks_cluster.main.version
    region                  = var.aws_region
    environment             = var.environment
    cloud_provider          = "AWS"
    node_group_size_desired = var.node_group_desired_size
    node_group_size_min     = var.node_group_min_size
    node_group_size_max     = var.node_group_max_size
    instance_types          = var.node_instance_types
    availability_zones      = var.availability_zones
    vpc_id                  = aws_vpc.main.id
    public_subnets          = length(aws_subnet.public)
    private_subnets         = length(aws_subnet.private)
  }
}

# Full Infrastructure Summary for AWS
output "infrastructure_summary" {
  description = "Complete AWS infrastructure deployment summary"
  value = {
    # EKS
    eks = {
      cluster_id       = aws_eks_cluster.main.id
      cluster_endpoint = aws_eks_cluster.main.endpoint
      cluster_version  = aws_eks_cluster.main.version
    }
    # RDS
    rds = var.rds_master_password != "" ? {
      endpoint       = aws_db_instance.main.endpoint
      database_name  = aws_db_instance.main.db_name
      engine_version = aws_db_instance.main.engine_version
      multi_az       = aws_db_instance.main.multi_az
      secret_arn     = aws_secretsmanager_secret.rds_password.arn
    } : null
    # S3
    s3 = {
      bucket_id          = aws_s3_bucket.main.id
      bucket_domain_name = aws_s3_bucket.main.bucket_regional_domain_name
      log_bucket_id      = aws_s3_bucket.log.id
    }
    # CloudFront
    cloudfront = {
      distribution_id   = aws_cloudfront_distribution.main.id
      distribution_domain = aws_cloudfront_distribution.main.domain_name
    }
    # Route53
    route53 = var.route53_create_hosted_zone ? {
      zone_id = aws_route53_zone.main[0].zone_id
      nameservers = aws_route53_zone.main[0].name_servers
    } : null
  }
}
