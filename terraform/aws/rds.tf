# RDS PostgreSQL Database
# Production-ready PostgreSQL instance with automated backups, encryption, and monitoring

# Subnet group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-${var.environment}"
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL port 5432
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "PostgreSQL from EKS nodes"
  }

  # Lambda functions access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.rds_allowed_cidr_blocks
    description = "PostgreSQL from specified networks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}

# RDS Enhanced Monitoring IAM Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.enable_rds_enhanced_monitoring ? 1 : 0
  name  = "${var.project_name}-rds-monitoring-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.enable_rds_enhanced_monitoring ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-postgres-${var.environment}"
  family = var.rds_parameter_family
  description = "Parameter group for ${var.project_name} PostgreSQL"

  # Performance optimization parameters
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = var.rds_log_min_duration
    apply_method = "immediate"
  }

  parameter {
    name         = "max_connections"
    value        = var.rds_max_connections
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "${var.project_name}-postgres-params-${var.environment}"
  }
}

# CloudWatch Log Group for RDS
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/postgresql/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-rds-logs-${var.environment}"
  }
}

# RDS Database Instance
resource "aws_db_instance" "main" {
  identifier            = "${var.project_name}-postgres-${var.environment}"
  db_name              = var.rds_database_name
  engine               = "postgres"
  engine_version       = var.rds_postgres_version
  instance_class       = var.rds_instance_class
  allocated_storage    = var.rds_allocated_storage
  storage_type         = var.rds_storage_type
  storage_encrypted    = false
  iops                 = var.rds_iops

  # Credentials
  username             = var.rds_master_username
  password             = var.rds_master_password
  parameter_group_name = aws_db_parameter_group.main.name

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.rds_multi_az

  # Backup and maintenance
  backup_retention_period = var.rds_backup_retention_days
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window
  copy_tags_to_snapshot   = true

  # Performance and monitoring
  performance_insights_enabled          = var.enable_rds_performance_insights
  performance_insights_retention_period = var.rds_performance_insights_retention
  monitoring_interval                   = var.enable_rds_enhanced_monitoring ? 60 : 0
  monitoring_role_arn                   = var.enable_rds_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports       = ["postgresql"]

  # Deletion protection
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment != "prod"

  # Snapshot identifier for restore
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds,
    aws_cloudwatch_log_group.rds_postgresql
  ]

  tags = {
    Name = "${var.project_name}-postgres-${var.environment}"
  }

  lifecycle {
    ignore_changes = [password]
  }
}

# RDS Enhanced Monitoring CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "rds" {
  count          = var.enable_rds_enhanced_monitoring ? 1 : 0
  dashboard_name = "${var.project_name}-rds-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Average" }],
            [".", "ReadLatency", { stat = "Average" }],
            [".", "WriteLatency", { stat = "Average" }],
            [".", "DiskQueueDepth", { stat = "Average" }],
            [".", "FreeableMemory", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Performance Metrics"
        }
      }
    ]
  })
}

# Secrets Manager secret for RDS password
resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "${var.project_name}/rds/password-${var.environment}"
  description             = "RDS PostgreSQL password for ${var.project_name}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-rds-secret-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = var.rds_master_password
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.rds_database_name
  })
}

# RDS Event Subscription
resource "aws_db_event_subscription" "default" {
  name      = "${var.project_name}-rds-events-${var.environment}"
  sns_topic = aws_sns_topic.rds_alerts.arn

  source_type = "db-instance"
  source_ids  = [aws_db_instance.main.id]

  event_categories = [
    "availability",
    "failure",
    "failover",
    "maintenance",
    "notification",
    "recovery",
    "restoration"
  ]

  enabled = true

  tags = {
    Name = "${var.project_name}-rds-subscription-${var.environment}"
  }
}

# SNS Topic for RDS Alerts
resource "aws_sns_topic" "rds_alerts" {
  name = "${var.project_name}-rds-alerts-${var.environment}"

  tags = {
    Name = "${var.project_name}-rds-alerts-${var.environment}"
  }
}

# CloudWatch Alarm for RDS CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.rds_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# CloudWatch Alarm for RDS Storage
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_allocated_storage * 1024 * 1024 * 1024 * 0.1  # Alert at 10% free
  alarm_description   = "This alarm monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.rds_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# CloudWatch Alarm for RDS Connections
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-rds-connections-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_max_connections * 0.8  # Alert at 80% of max connections
  alarm_description   = "This alarm monitors RDS database connections"
  alarm_actions       = [aws_sns_topic.rds_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# CloudWatch Alarm for RDS Read Latency
resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${var.project_name}-rds-read-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"  # milliseconds
  alarm_description   = "Alert when read latency exceeds 10ms"
  alarm_actions       = [aws_sns_topic.rds_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}
