# Terraform AWS Infrastructure for Weather Tracker

Complete Terraform configuration to provision a highly available Kubernetes cluster on AWS EKS with state-of-the-art networking, security, and monitoring.

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│            AWS Account                           │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                       │  │
│  │                                          │  │
│  │  ┌─ AZ1                 ┌─ AZ2          │  │
│  │  │  Public Subnet (x1)  │  Public       │  │
│  │  │  ↓                   │  Subnet (x1)  │  │
│  │  │  NAT Gateway         │  NAT Gateway  │  │
│  │  │  ↓                   │  ↓            │  │
│  │  │  Private Subnet      │  Private      │  │
│  │  │  EKS Nodes           │  Subnet       │  │
│  │  │                      │  EKS Nodes    │  │
│  │  └─────────────────────┴─────────────   │  │
│  │                                          │  │
│  │  ┌──────────────────────────────────┐   │  │
│  │  │  EKS Control Plane               │   │  │
│  │  │  (Managed by AWS)                │   │  │
│  │  │  - API Server                    │   │  │
│  │  │  - Control Plane Logging         │   │  │
│  │  │  - OIDC Provider (IRSA)          │   │  │
│  │  └──────────────────────────────────┘   │  │
│  │                                          │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  VPC Flow Logs → CloudWatch Logs         │  │
│  │  EKS Cluster Logs → CloudWatch Logs      │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
└─────────────────────────────────────────────────┘
```

## File Structure

```
terraform/
├── provider.tf              # Terraform and provider configuration
├── variables.tf             # Input variables with validation
├── vpc.tf                   # Network infrastructure (VPC, subnets, NAT, etc)
├── eks.tf                   # EKS cluster, node group, IAM roles
├── outputs.tf               # Output values for integration
├── terraform.tfvars.example # Example variable overrides
└── README.md                # This file
```

## Key Features

### Networking
- **High Availability**: Multi-AZ deployment (2-3 availability zones)
- **Public/Private Subnets**: DMZ pattern with NAT Gateway for outbound access
- **VPC Flow Logs**: Network traffic monitoring to CloudWatch
- **Security Groups**: Separate control plane and worker node security groups
- **Optional VPN Gateway**: For hybrid cloud connectivity

### EKS Cluster
- **Managed Kubernetes**: AWS-managed control plane (1.28+)
- **Control Plane Logging**: 5 log types (API, audit, authenticator, controller manager, scheduler)
- **Encryption**: KMS encryption for secrets at rest
- **Endpoint Access**: Public and/or private API endpoint configuration
- **IAM Roles**: Cluster and node group IAM roles with least privilege

### Node Group
- **Auto Scaling**: Configurable desired/min/max capacity (default: 3/1/10 nodes)
- **Instance Types**: Configurable (default: t3.medium, t3.large)
- **Capacity Types**: ON_DEMAND or SPOT for cost optimization
- **Update Strategy**: Rolling updates for zero-downtime upgrades
- **EBS Encryption**: Encrypted root volumes with KMS

### Identity & Access Management
- **IRSA Support**: OIDC Provider for Kubernetes Service Account integration
- **Cluster Autoscaler**: IAM role and policy for automatic node scaling
- **SSM Session Manager**: EC2 instance manager access without SSH
- **CloudWatch Agent**: Monitoring permissions for container insights

### Observability
- **CloudWatch Logs**: Centralized logging for control plane and VPC flow
- **Log Retention**: Configurable retention (default: 7 days)
- **EKS Metrics**: Integration with CloudWatch Container Insights
- **Deployment Summary**: Output shows cluster configuration overview

## Prerequisites

1. **AWS Account** with appropriate permissions for:
   - EKS cluster creation
   - VPC and networking resources
   - IAM role creation
   - CloudWatch log groups
   - KMS key management (optional for encryption)

2. **Terraform** >= 1.0
   ```bash
   terraform --version
   ```

3. **AWS CLI** >= 2.0
   ```bash
   aws --version
   aws configure  # Configure your AWS credentials
   ```

4. **kubectl**
   ```bash
   kubectl version --client
   ```

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

This downloads required providers (AWS, Kubernetes, TLS).

### 2. Review and Customize Variables

Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize:
```hcl
environment                = "prod"
eks_version                = "1.28"
node_group_desired_size    = 3
node_instance_types        = ["t3.medium"]
enable_cluster_autoscaling = true
```

### 3. Validate Configuration

```bash
terraform validate
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output to verify resources to be created:
- 1 VPC + networking components
- 2-3 public subnets + 2-3 private subnets
- 2-3 NAT Gateways (for HA)
- 1 EKS Cluster
- 1 EKS Node Group
- 1 OIDC Provider
- IAM roles and policies

### 5. Apply Configuration

```bash
terraform apply tfplan
```

Deployment time: **15-20 minutes** for EKS cluster creation

### 6. Configure kubectl

After successful deployment, configure kubectl:

```bash
# Get the command from outputs
terraform output configure_kubectl

# Or manually:
aws eks update-kubeconfig --region us-east-1 --name weather-tracker-prod
```

Verify cluster access:
```bash
kubectl get nodes
kubectl get pods -A
```

## Variable Reference

### Core Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region |
| `environment` | string | `prod` | Environment (dev, staging, prod) |
| `project_name` | string | `weather-tracker` | Project name for resource naming |

### VPC Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_cidr` | string | `10.0.0.0/16` | VPC CIDR block |
| `availability_zones` | number | `2` | Number of AZs (2 or 3) |
| `enable_nat_gateway` | bool | `true` | Enable NAT Gateway |
| `enable_vpn_gateway` | bool | `false` | Enable VPN Gateway |

### EKS Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `eks_version` | string | `1.28` | Kubernetes version (1.28+) |
| `eks_endpoint_private_access` | bool | `true` | Enable private API endpoint |
| `eks_endpoint_public_access` | bool | `true` | Enable public API endpoint |
| `eks_public_access_cidrs` | list(string) | `["0.0.0.0/0"]` | CIDR blocks for API access |

### Node Group Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `node_group_desired_size` | number | `3` | Desired node count |
| `node_group_min_size` | number | `1` | Minimum node count |
| `node_group_max_size` | number | `10` | Maximum node count |
| `node_instance_types` | list(string) | `["t3.medium", "t3.large"]` | EC2 instance types |
| `node_disk_size` | number | `50` | Root volume size (GB) |
| `node_group_capacity_type` | string | `ON_DEMAND` | Capacity type (ON_DEMAND or SPOT) |

### Monitoring & Logging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_retention_days` | number | `7` | CloudWatch log retention |
| `enable_cluster_autoscaling` | bool | `true` | Enable cluster autoscaler |
| `enable_high_availability` | bool | `true` | Enable HA configuration |

## Outputs

Key outputs available after deployment:

```bash
terraform output                    # Show all outputs
terraform output eks_cluster_id     # Get cluster ID
terraform output eks_cluster_endpoint # Get API endpoint
terraform output configure_kubectl  # Get kubectl command
terraform output deployment_summary # Show full deployment details
```

## Connecting Your Application

After cluster deployment, deploy the weather tracker application:

### 1. Create Kubernetes Manifests

Create `k8s/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weather-tracker-api
  labels:
    app: weather-tracker-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: weather-tracker-api
  template:
    metadata:
      labels:
        app: weather-tracker-api
    spec:
      containers:
      - name: api
        image: YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: OPENWEATHER_API_KEY
          valueFrom:
            secretKeyRef:
              name: weather-tracker-secrets
              key: api-key
        - name: REDIS_HOST
          value: redis-service
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
```

### 2. Create Service and Secrets

```bash
# Create secret
kubectl create secret generic weather-tracker-secrets \
  --from-literal=api-key=$OPENWEATHER_API_KEY

# Deploy application
kubectl apply -f k8s/deployment.yaml

# Verify
kubectl get pods
kubectl get svc
```

## Cost Optimization

### Development Environment
```hcl
# Use smaller cluster
node_group_desired_size = 1
node_instance_types     = ["t3.small"]
environment             = "dev"
```

### Spot Instances for Cost Savings
```hcl
node_group_capacity_type = "SPOT"  # Up to 90% savings
```

Estimated monthly cost:
- **t3.medium ON_DEMAND**: ~$30/month per node
- **t3.medium SPOT**: ~$3-9/month per node
- **NAT Gateway**: ~$32/month (1 per AZ)
- **EKS Cluster**: $0.10/hour (~$73/month)

## Maintenance & Operations

### Cluster Upgrades

Update Kubernetes version:
```bash
# Update variable
terraform apply -var="eks_version=1.29"
```

### Scaling Nodes

Adjust node count:
```bash
terraform apply -var="node_group_desired_size=5"
```

### Backup and Recovery

Enable EBS snapshots:
```bash
# In Kubernetes, use persistent volumes with snapshots
kubectl apply -f k8s/pvc.yaml
```

### Monitoring & Logs

View EKS cluster logs:
```bash
aws logs tail /aws/eks/weather-tracker-prod/cluster --follow
```

View VPC Flow Logs:
```bash
aws logs tail /aws/vpc/eni-flows --follow
```

## Troubleshooting

### Pods Not Starting
1. Check node status: `kubectl get nodes`
2. Check pod events: `kubectl describe pod POD_NAME`
3. Check logs: `kubectl logs -f POD_NAME`

### Insufficient Capacity
1. Scale up node group: `terraform apply -var="node_group_desired_size=5"`
2. Or enable SPOT instances for flexibility

### API Endpoint Not Accessible
1. Verify security group rules
2. Check `eks_public_access_cidrs` variable
3. Ensure IAM user/role has EKS permissions

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete:
- EKS cluster
- All node groups and EC2 instances
- VPC and networking resources
- IAM roles
- CloudWatch log groups

Cost savings: Full expense stops immediately.

## Advanced Configuration

### High Availability Best Practices

1. **Multiple AZs**: Set `availability_zones = 3`
2. **Pod Disruption Budgets**: Ensure graceful deployments
3. **Network Policies**: Restrict inter-pod communication
4. **Resource Limits**: Prevent node resource exhaustion

### Security Best Practices

1. **Restrict Public Access**: Update `eks_public_access_cidrs`
   ```hcl
   eks_public_access_cidrs = ["203.0.113.0/24"]  # Your corporate IP range
   ```

2. **Enable Pod Security Policies**: `enable_pod_security_policy = true`

3. **Use IAM Roles for Service Accounts (IRSA)**:
   ```yaml
   # In your pod spec
   serviceAccountName: my-service-account
   ```

### Cost Monitoring

Use AWS Cost Explorer to track spending by tag:
```bash
# Tags are automatically applied to all resources
# Filter by: Managed=Terraform, Environment=prod, Project=weather-tracker
```

## Support & Further Reading

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes on EKS Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/best-practices.html)

## License

This Terraform configuration is part of the weather-tracker project.
