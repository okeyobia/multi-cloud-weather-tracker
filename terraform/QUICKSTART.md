# Terraform Quick Start Guide

Get an AWS EKS cluster running in 5 steps.

## Prerequisites
- AWS account with permissions
- `terraform` installed (`brew install terraform`)
- `aws` CLI configured (`aws configure`)
- `kubectl` installed (`brew install kubectl`)

## 5-Minute Deploy

### Step 1: Initialize
```bash
cd terraform
terraform init
```

### Step 2: Copy Variables (Optional)
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if you want to customize (optional - defaults work)
```

### Step 3: Review Plan
```bash
terraform plan
```

### Step 4: Deploy
```bash
terraform apply
```

Type `yes` when prompted. **Wait 15-20 minutes for cluster creation.**

### Step 5: Connect
```bash
# Get the connection command
aws eks update-kubeconfig --region us-east-1 --name weather-tracker-prod

# Verify
kubectl get nodes
kubectl get pods -A
```

## What Gets Created

| Resource | Count | Details |
|----------|-------|---------|
| VPC | 1 | 10.0.0.0/16 CIDR |
| Subnets | 4-6 | 2-3 public + 2-3 private |
| NAT Gateways | 2-3 | One per AZ for HA |
| Internet Gateway | 1 | Public internet access |
| EKS Cluster | 1 | Managed Kubernetes 1.28+ |
| EKS Node Group | 1 | 3 nodes (t3.medium/large) |
| Security Groups | 2 | Control plane + nodes |
| IAM Roles | 3 | Cluster, nodes, autoscaler |
| CloudWatch Logs | 2 | EKS control plane + VPC flow logs |
| KMS Keys | 1 | For encryption at rest |

## Customization

Edit `terraform.tfvars`:

```hcl
# Smaller cluster for development
environment             = "dev"
node_group_desired_size = 1
node_instance_types     = ["t3.small"]

# Cost optimization with SPOT instances
node_group_capacity_type = "SPOT"

# Restrict API access
eks_public_access_cidrs = ["203.0.113.0/24"]  # Your IP range
```

Then apply:
```bash
terraform apply
```

## Cleanup

```bash
terraform destroy
```

## Common Commands

```bash
# Show deployment details
terraform output deployment_summary

# Get cluster endpoint
terraform output eks_cluster_endpoint

# Get cluster ID
terraform output eks_cluster_id

# List all outputs
terraform output

# Specific output
terraform output eks_node_group_id
```

## Troubleshooting

**Error: "No valid credential sources found"**
```bash
aws configure
```

**Cluster creation hanging?**
- Check AWS console EKS page
- Usually takes 15-20 minutes
- Be patient!

**Can't connect with kubectl?**
```bash
aws eks update-kubeconfig --region us-east-1 --name weather-tracker-prod
kubectl get nodes  # Should list 3 nodes
```

**Pods stuck in Pending?**
```bash
# Check node capacity
kubectl get nodes
kubectl describe node NODE_NAME

# Or scale up
terraform apply -var="node_group_desired_size=5"
```

## Next Steps

Deploy your application:

```bash
# Create ECR repository for Docker image
aws ecr create-repository --repository-name weather-tracker

# Push your image from backend/
cd ../backend
docker build -t weather-tracker .
docker tag weather-tracker:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest

# Create namespace for application
kubectl create namespace weather-tracker

# Create secret from .env
kubectl create secret generic weather-tracker-secrets \
  --from-literal=openweather-api-key=$OPENWEATHER_API_KEY \
  -n weather-tracker

# Create deployment manifest in k8s/deployment.yaml (see README.md)
kubectl apply -f k8s/deployment.yaml -n weather-tracker

# Verify deployment
kubectl get pods -n weather-tracker
kubectl get svc -n weather-tracker
```

## Cost

Typical monthly cost:

```
EKS Cluster:         $73  (flat fee)
3x t3.medium nodes: $90  ($30/month each)
NAT Gateways (2):   $64  ($32/month each)
CloudWatch Logs:    ~$5
─────────────────────────
Total:             ~$232/month

With SPOT instances: ~$50 for nodes → $122/month total
```

## Need Help?

See [README.md](README.md) for detailed documentation.
