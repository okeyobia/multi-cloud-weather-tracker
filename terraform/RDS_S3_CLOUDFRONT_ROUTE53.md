# Production Infrastructure with RDS, S3, CloudFront & Route53

This guide explains the newly created infrastructure components beyond EKS and networking.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Users                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   Route53 DNS       │
        │  (Failover records) │
        └─────────────────────┘
                  │
        ┌─────────┴──────────┐
        │                    │
        ▼                    ▼
   ┌─────────┐         ┌──────────┐
   │ Primary │         │ Secondary│
   │ CF Dist │◄────────│ CF Dist  │ (failover)
   └────┬────┘         └──────────┘
        │
   ┌────┴──────────────────────┐
   │                           │
   ▼                           ▼
  ┌─────┐                   ┌─────────┐
  │ S3  │                   │ API/ALB │
  │Bucket│                  │(EKS LB) │
  └─────┘                   └────┬────┘
        │                        │
        └────────────┬───────────┘
                     │
              ┌──────▼──────┐
              │   RDS PG    │
              │ (Multi-AZ)  │
              └─────────────┘
```

## New Infrastructure Components

### 1. RDS PostgreSQL Database

Production-grade relational database with:
- **Multi-AZ Deployment**: Automatic failover to standby instance
- **Automated Backups**: 30-day retention with point-in-time recovery
- **Encryption**: KMS encryption at rest
- **Enhanced Monitoring**: CloudWatch integration with 60-second granularity
- **Performance Insights**: Real-time database performance analysis
- **Automated Failover**: 2-3 minute recovery on instance failure
- **CloudWatch Alarms**: CPU, storage, connections, and latency monitoring

**Configuration:**
- Engine: PostgreSQL 15.4
- Instance: db.t4g.medium (default)
- Storage: 100GB gp3 (General Purpose SSD)
- Backup Window: 03:00-04:00 UTC
- Maintenance Window: Sunday 04:00-05:00 UTC

**Connection:**
```bash
# Retrieved from Secrets Manager
HOST: <rds-endpoint>
PORT: 5432
DB: weatherdb
USER: postgres
PASSWORD: <stored securely>
```

### 2. S3 Bucket Storage

Secure object storage for static assets and backups:
- **Versioning Enabled**: Protect against accidental deletion
- **Encryption**: KMS-encrypted at rest
- **Access Logging**: Track all S3 access via CloudFront OAI
- **Lifecycle Policies**: 
  - Archive old versions to Glacier after 90 days
  - Delete after 1 year
  - Automatic cleanup of incomplete uploads
- **CORS Configuration**: Allow cross-origin requests for API
- **Public Access Block**: Prevent accidental public exposure

**Use Cases:**
- Static web assets (CSS, JS, images)
- Database backups
- Application logs and analytics
- Disaster recovery files

### 3. CloudFront Distribution

Global content delivery with edge caching:
- **Dual Origins**:
  - Primary: S3 bucket (for static content)
  - Secondary: API/ALB (for dynamic requests)
- **Cache Behaviors**:
  - `/api/*` → API origin (no caching, pass all headers)
  - `/assets/*` → S3 (1-year cache)
  - `/health` → API (60-second cache for health checks)
  - Default → S3 (1-hour cache)
- **Compression**: Automatic GZIP/Brotli compression
- **Security**:
  - HTTPS everywhere with automatic redirect
  - Optional WAF integration
  - DDoS protection via AWS Shield Standard
- **Geo-Restriction**: Optional country-level restrictions
- **Performance**: 
  - HTTP/2 and HTTP/3 support
  - Edge location caching
  - Origin Shield for additional layer

**Price Class Options:**
- `PriceClass_100`: US, Europe, Asia (lower latency, higher cost)
- `PriceClass_200`: Above + additional regions
- `PriceClass_All`: All regions (best performance, highest cost)

### 4. Route53 DNS with Failover

Intelligent DNS with automatic failover and health checks:
- **Primary Record**: Points to primary CloudFront distribution
- **Secondary Record**: Automatic failover to secondary (if configured)
- **Health Checks**:
  - Monitors `/health` endpoint on primary
  - Failure threshold: 3 consecutive failures (90 seconds)
  - Measurement interval: 30 seconds
  - Latency measurement enabled
- **DNS Query Logging**: CloudWatch integration for audit trail
- **Subdomains**:
  - `api.yourdomain.com` → API endpoint
  - `weather.yourdomain.com` → Weather service
  - `www.yourdomain.com` → WWW alias

**Failover Behavior:**
1. Route53 checks primary health endpoint every 30 seconds
2. If 3 consecutive checks fail, marks as unhealthy
3. DNS queries redirect to secondary destination
4. Automatic recovery when primary becomes healthy

## Deployment Guide

### Prerequisites

1. **AWS Account** with permissions for:
   - RDS, S3, CloudFront, Route53
   - KMS, Secrets Manager
   - CloudWatch Logs and Alarms

2. **Variables Configuration**:
   ```hcl
   # terraform.tfvars
   rds_master_password = "SecurePassword123!"
   cloudfront_api_domain_name = "api-lb.example.com"
   route53_domain_name = "yourdomain.com"
   ```

### Step 1: Configure Terraform Variables

Update `terraform.tfvars`:

```hcl
# RDS Configuration
rds_instance_class          = "db.t4g.medium"
rds_allocated_storage       = 100
rds_postgres_version        = "15.4"
rds_master_password         = "P@ssw0rd123!456"  # Use AWS Secrets Manager in production
rds_multi_az                = true
enable_rds_enhanced_monitoring = true
enable_rds_performance_insights = true

# S3 Configuration
s3_cors_allowed_origins     = ["https://yourdomain.com"]
enable_s3_replication       = false

# CloudFront Configuration
cloudfront_api_domain_name  = "api.k8s...elb.amazonaws.com"
cloudfront_price_class      = "PriceClass_100"
cloudfront_use_default_certificate = true

# Route53 Configuration
route53_domain_name         = "yourdomain.com"
route53_create_hosted_zone  = true
route53_enable_secondary    = false
route53_enable_calculated_health_check = true
```

### Step 2: Plan Deployment

```bash
cd terraform
terraform plan -out=tfplan
```

Review the plan output to verify:
- 1 RDS instance (Multi-AZ)
- 2 S3 buckets (main + logs)
- 1 CloudFront distribution
- 4-6 Route53 records
- KMS keys for encryption
- CloudWatch log groups and alarms

### Step 3: Deploy Infrastructure

```bash
terraform apply tfplan
```

Approximate time:
- RDS: 10-15 minutes
- S3: Immediate
- CloudFront: 10-15 minutes for propagation
- Route53: Immediate

### Step 4: Retrieve Connection Information

```bash
# RDS connection details
terraform output rds_endpoint
terraform output rds_address
terraform output rds_secret_arn

# S3 bucket details
terraform output s3_bucket_id
terraform output s3_bucket_domain_name

# CloudFront details
terraform output cloudfront_domain_name
terraform output cloudfront_distribution_id

# Route53 details
terraform output route53_zone_id
terraform output route53_zone_nameservers
```

### Step 5: Configure Application

Update Kubernetes ConfigMap with database connection:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: weather-tracker-config
  namespace: weather-tracker
data:
  DATABASE_URL: "postgresql://postgres:PASSWORD@<rds-endpoint>:5432/weatherdb"
  S3_BUCKET: "<s3-bucket-id>"
  CLOUDFRONT_DOMAIN: "<cloudfront-domain>"
  REDIS_HOST: "redis-service.weather-tracker.svc.cluster.local"
```

### Step 6: Point Domain to Route53

Update domain registrar:

```
yourdomainregistrar.com:

NS Records:
  ns-123.awsdns-12.com
  ns-456.awsdns-34.co.uk
  ns-789.awsdns-56.net
  ns-012.awsdns-78.org
```

## Configuration Examples

### High-Performance RDS Setup

```hcl
rds_instance_class  = "db.r6i.xlarge"  # Memory optimized
rds_allocated_storage = 500
rds_storage_type    = "io2"            # High I/O performance
rds_iops            = 16000
enable_rds_performance_insights = true
rds_performance_insights_retention = 31  # 31 days
```

### Global CloudFront with Multi-Region

```hcl
cloudfront_price_class = "PriceClass_All"  # All edge locations
route53_enable_secondary = true
route53_secondary_cloudfront_domain = "<secondary-cf-domain>"
```

### Secure S3 with Replication

```hcl
enable_s3_replication = true
s3_replication_destination_arn = "arn:aws:s3:::secondary-bucket-region2"
```

### Advanced Route53 with Traffic Policy

```hcl
route53_enable_traffic_policy = true
route53_enable_resolver_endpoint = true  # Hybrid DNS
route53_resolver_domain_name = "internal.company.local"
```

## Monitoring & Operations

### CloudWatch Dashboards

Automatically created dashboards:
- **RDS Dashboard**: CPU, connections, latency, storage
- **CloudFront Dashboard**: Requests, cache hit rate, error rates
- **Route53 Dashboard**: Health check status, DNS query metrics

View dashboards:
```bash
aws cloudwatch get-dashboard --dashboard-name weather-tracker-rds-prod
aws cloudwatch get-dashboard --dashboard-name weather-tracker-cloudfront-prod
```

### CloudWatch Alarms

Automatic alarms for:
- **RDS**: CPU > 80%, Storage < 10%, Connections > 80%, Read latency > 10ms
- **CloudFront**: 4xx errors > 5%, 5xx errors > 1%, Cache hit rate < 50%
- **Route53**: Primary health check failures, DNS resolution latency

### Application Monitoring

Connect application to RDS:
```python
# Example: FastAPI + SQLAlchemy
from sqlalchemy import create_engine
import boto3

# Retrieve password from Secrets Manager
sm = boto3.client('secretsmanager')
secret = sm.get_secret_value(SecretId='weather-tracker/rds/password-prod')
creds = json.loads(secret['SecretString'])

DATABASE_URL = f"postgresql://{creds['username']}:{creds['password']}@{creds['host']}:5432/weatherdb"

engine = create_engine(DATABASE_URL)
```

### Database Backups

Automated backups retained for 30 days:
```bash
# List available backups
aws rds describe-db-snapshots \
  --db-instance-identifier weather-tracker-postgres-prod

# View backup details
aws rds describe-db-snapshots \
  --db-snapshot-identifier weather-tracker-postgres-prod-backup-date
```

### S3 Content Upload

Upload static assets:
```bash
# Sync frontend assets to S3
aws s3 sync frontend/dist/ s3://weather-tracker-prod-xxx/assets/

# Set cache headers
aws s3 sync frontend/dist/ s3://weather-tracker-prod-xxx/ \
  --cache-control "max-age=3600" \
  --exclude "*" --include "*.html"
```

### CloudFront Cache Invalidation

Invalidate cached content after updates:
```bash
# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"

# Invalidate specific path
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/api/weather/*"

# Check invalidation status
aws cloudfront list-invalidations \
  --distribution-id <distribution-id>
```

## Cost Optimization

### RDS Cost Reduction

```hcl
# Use smaller instance for dev/staging
rds_instance_class = "db.t4g.small"

# Or use Aurora Serverless for variable workloads
# (would require different Terraform configuration)
```

### S3 Cost Reduction

```hcl
# Enable versioning cleanup
# Archive to Glacier after 30 days (configured in lifecycle)

# Use S3 Intelligent-Tiering
# (requires additional configuration)
```

### CloudFront Cost Reduction

```hcl
# Use Price Class 200 instead of All
cloudfront_price_class = "PriceClass_200"

# Reduce edge TTL for frequently updating content
default_ttl = 300  # 5 minutes instead of 1 hour
```

### Route53 Cost Reduction

```hcl
# Reduce health check frequency
# Default: 30 seconds
# Could change to: 30 seconds simple checks instead of full HTTPS
```

## Troubleshooting

### RDS Connection Issues

```bash
# Test from Kubernetes pod
kubectl exec -it deployment/weather-tracker-api -n weather-tracker -- \
  psql -h <rds-endpoint> -U postgres -d weatherdb -c "SELECT 1;"

# Check security group
aws ec2 describe-security-groups \
  --group-ids <rds-sg-id>
```

### CloudFront Not Updating

```bash
# Check distribution status
aws cloudfront get-distribution --id <distribution-id>

# View recent invalidations
aws cloudfront list-invalidations --distribution-id <distribution-id>

# Create new invalidation
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"
```

### Route53 Failover Not Working

```bash
# Check health of primary
aws route53 get-health-check-status \
  --health-check-id <health-check-id>

# View health check details
aws route53 get-health-check \
  --health-check-id <health-check-id>

# Create test query
dig yourdomain.com @ns-123.awsdns-12.com +short
```

## Best Practices

### Security
- [ ] Enable MFA Delete on S3 bucket
- [ ] Restrict CloudFront IP access via WAF
- [ ] Rotate RDS password regularly
- [ ] Use Secrets Manager for credential storage
- [ ] Enable VPC Flow Logs for monitoring
- [ ] Restrict RDS security group to only EKS nodes

### Performance
- [ ] Use RDS read replicas for read-heavy workloads
- [ ] Enable CloudFront caching for static assets
- [ ] Use S3 Intelligent-Tiering for cost optimization
- [ ] Set appropriate cache TTLs for different content types
- [ ] Monitor CloudFront cache hit ratio

### Reliability
- [ ] Test failover manually
- [ ] Verify backup restoration process monthly
- [ ] Monitor health check metrics
- [ ] Set up CloudWatch alarms
- [ ] Document disaster recovery procedures

### Cost Management
- [ ] Use AWS Cost Explorer to track spending
- [ ] Schedule RDS downtime for dev environments
- [ ] Use Reserved Instances for production
- [ ] Monitor S3 storage growth
- [ ] Review CloudFront usage by distribution

## Support & Resources

- [Amazon RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Amazon CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Amazon Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Quick Command Reference

```bash
# View all outputs
terraform output

# View specific resource
terraform output rds_endpoint
terraform output cloudfront_domain_name
terraform output route53_zone_id

# Refresh state
terraform refresh

# Destroy all resources
terraform destroy

# Get RDS password from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id weather-tracker/rds/password-prod \
  --query SecretString --output text | jq .password
```
