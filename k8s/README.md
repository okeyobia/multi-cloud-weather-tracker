# Kubernetes Deployment Guide for Weather Tracker

Deploy the weather tracker application to the AWS EKS cluster provisioned by Terraform.

## Prerequisites

1. **EKS Cluster**: Created by Terraform (`terraform/`)
2. **kubectl**: Configured to access your cluster
3. **Docker Image**: Built and pushed to ECR
4. **OpenWeather API Key**: From https://openweathermap.org/api

## Architecture

```
┌─────────────────────────────────────────┐
│  AWS EKS Cluster (weather-tracker)     │
├─────────────────────────────────────────┤
│                                         │
│  ┌─── weather-tracker namespace ──┐    │
│  │                                │    │
│  │  ┌───────────────────────┐    │    │
│  │  │  Weather Tracker API  │    │    │
│  │  │  (3 replicas, HPA)    │ ←──┤────┼─ LoadBalancer Service
│  │  │  - Deployment         │    │    │   (http://api.example.com)
│  │  │  - Auto-scaling       │    │    │
│  │  │  - Health checks      │    │    │
│  │  └───────────────────────┘    │    │
│  │            ↓                   │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  Redis Cache         │     │    │
│  │  │  - StatefulSet       │     │    │
│  │  │  - PersistentVolume  │     │    │
│  │  │  - 5GB EBS storage   │     │    │
│  │  └──────────────────────┘     │    │
│  │                                │    │
│  │  ┌──────────────────────┐     │    │
│  │  │  Config & Secrets    │     │    │
│  │  │  - ConfigMap         │     │    │
│  │  │  - Secret            │     │    │
│  │  └──────────────────────┘     │    │
│  └────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

## File Overview

| File | Purpose | Contains |
|------|---------|----------|
| `deployment.yaml` | Weather tracker API | Deployment, Service, ConfigMap, Secret, HPA, PDB |
| `redis-deployment.yaml` | Redis cache backend | StatefulSet, PersistentVolume, Storage Class, NetworkPolicy |

## Quick Start

### 1. Build and Push Docker Image

```bash
# From backend/ directory
docker build -t weather-tracker:latest .

# Tag for ECR
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker tag weather-tracker:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest

# Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest
```

### 2. Update Image in Deployment

Edit `deployment.yaml` and update the image:

```yaml
containers:
- name: api
  image: $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest
```

### 3. Set API Key Secret

```bash
# Create the namespace first (if not done already)
kubectl create namespace weather-tracker

# Create secret with your API key
kubectl create secret generic weather-tracker-secrets \
  --from-literal=openweather-api-key=$OPENWEATHER_API_KEY \
  -n weather-tracker

# Or from a file
echo -n "$OPENWEATHER_API_KEY" > /tmp/api-key.txt
kubectl create secret generic weather-tracker-secrets \
  --from-file=openweather-api-key=/tmp/api-key.txt \
  -n weather-tracker
```

### 4. Deploy Redis

```bash
kubectl apply -f redis-deployment.yaml
```

Wait for Redis to be ready:
```bash
kubectl rollout status statefulset/redis -n weather-tracker --timeout=5m
kubectl get pods -n weather-tracker -l app=redis
```

### 5. Deploy Weather Tracker API

```bash
kubectl apply -f deployment.yaml
```

Verify deployment:
```bash
kubectl rollout status deployment/weather-tracker-api -n weather-tracker --timeout=5m
kubectl get pods -n weather-tracker -l app=weather-tracker-api
kubectl get svc -n weather-tracker
```

### 6. Access the Application

Get the LoadBalancer endpoint:
```bash
kubectl get svc weather-tracker-service -n weather-tracker
# Copy the EXTERNAL-IP value

# Test the API
curl http://EXTERNAL-IP/health
curl http://EXTERNAL-IP/weather?city=London
```

## Configuration

### Environment Variables

Edit `deployment.yaml` ConfigMap section:

```yaml
data:
  LOG_LEVEL: "INFO"           # DEBUG, INFO, WARNING, ERROR
  REDIS_PORT: "6379"          # Redis port
  CACHE_TTL: "3600"           # Cache TTL in seconds (1 hour default)
  WORKERS: "4"                # Uvicorn workers
```

### Resource Limits

Adjust CPU/memory in `deployment.yaml`:

```yaml
resources:
  requests:
    cpu: 100m              # Guaranteed minimum resources
    memory: 128Mi
  limits:
    cpu: 500m              # Maximum consumption
    memory: 512Mi
```

### Replica Count

Change replicas in `deployment.yaml` or let HPA manage it:

```yaml
replicas: 3   # Minimum (HPA scales between 3-10)
```

### Storage Size

Adjust Redis storage in `redis-deployment.yaml`:

```yaml
resources:
  requests:
    storage: 5Gi  # Change as needed
```

## Scaling & Auto-Scaling

### Manual Scaling

Scale replicas manually:
```bash
kubectl scale deployment weather-tracker-api --replicas=5 -n weather-tracker
```

### Horizontal Pod Auto-Scaling (HPA)

HPA automatically scales between 3-10 replicas based on:
- CPU: 70% utilization threshold
- Memory: 80% utilization threshold

View HPA status:
```bash
kubectl get hpa -n weather-tracker
kubectl describe hpa weather-tracker-hpa -n weather-tracker
```

### Cluster Auto-Scaling

The Terraform-provisioned cluster autoscaler will scale EC2 nodes (1-10 nodes) based on pod resource requests.

## Monitoring & Troubleshooting

### Check Deployment Status

```bash
# Deployment status
kubectl describe deployment weather-tracker-api -n weather-tracker

# Recent events
kubectl get events -n weather-tracker --sort-by='.lastTimestamp'

# Pod details
kubectl describe pod POD_NAME -n weather-tracker
```

### View Logs

```bash
# Real-time logs
kubectl logs -f deployment/weather-tracker-api -n weather-tracker

# Last 100 lines
kubectl logs --tail=100 deployment/weather-tracker-api -n weather-tracker

# Redis logs
kubectl logs -f redis-0 -n weather-tracker
```

### Debug Connectivity

```bash
# Check if API can reach Redis
kubectl exec -it deployment/weather-tracker-api -n weather-tracker -- curl redis-service:6379

# Check DNS resolution
kubectl exec -it pod/POD_NAME -n weather-tracker -- nslookup redis-service

# Port forwarding to test locally
kubectl port-forward svc/weather-tracker-service 8000:80 -n weather-tracker
# Open http://localhost:8000/health
```

### Common Issues

**Pod stuck in Pending**
```bash
# Check resource requests vs node capacity
kubectl describe node NODE_NAME
kubectl top nodes
kubectl top pods -n weather-tracker

# Solution: Scale up cluster
terraform apply -var="node_group_desired_size=5"
```

**CrashLoopBackOff**
```bash
# Check logs for errors
kubectl logs POD_NAME -n weather-tracker

# Common causes:
# 1. Invalid secrets/API key
# 2. Unable to connect to Redis
# 3. Memory/CPU limits too low

# View events
kubectl describe pod POD_NAME -n weather-tracker
```

**Redis PVC not binding**
```bash
# Check PVC status
kubectl get pvc -n weather-tracker

# Check storage class
kubectl get storageclass

# Debugging
kubectl describe pvc redis-data-redis-0 -n weather-tracker

# May need EBS CSI driver installed:
# aws eks create-addon --cluster-name weather-tracker-prod --addon-name aws-ebs-csi-driver
```

## Operations

### Rolling Updates

Update deployment with new image:

```bash
# Update image
kubectl set image deployment/weather-tracker-api \
  api=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:v1.1.0 \
  -n weather-tracker

# Watch rollout progress
kubectl rollout status deployment/weather-tracker-api -n weather-tracker

# Rollback if needed
kubectl rollout undo deployment/weather-tracker-api -n weather-tracker
```

### Updating Configuration

Change ConfigMap:
```bash
# Edit ConfigMap
kubectl edit configmap weather-tracker-config -n weather-tracker

# Restart pods to pick up changes
kubectl rollout restart deployment/weather-tracker-api -n weather-tracker
```

Rotate secrets:
```bash
# Delete and recreate secret
kubectl delete secret weather-tracker-secrets -n weather-tracker

kubectl create secret generic weather-tracker-secrets \
  --from-literal=openweather-api-key=$NEW_API_KEY \
  -n weather-tracker

# Restart pods
kubectl rollout restart deployment/weather-tracker-api -n weather-tracker
```

### Backup & Recovery

Backup Redis data:
```bash
# Create manual snapshot (if appendonly enabled)
kubectl exec redis-0 -n weather-tracker -- redis-cli BGSAVE

# Copy PVC snapshot to S3
# Use AWS EBS snapshots via console or CLI
aws ec2 describe-volumes --filters="Name=tag:pvc.name,Values=redis-data-redis-0"
```

Recovery:
```bash
# Restore from EBS snapshot (create new volume from snapshot)
# Recreate PVC pointing to recovered volume
# Recreate StatefulSet
kubectl apply -f redis-deployment.yaml
```

### Monitoring & Metrics

With Prometheus installed:
```bash
# Forward to Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring

# Access http://localhost:9090
```

View weather tracker metrics:
```bash
# Port-forward to API
kubectl port-forward svc/weather-tracker-service 8000:80 -n weather-tracker

# Get metrics
curl http://localhost:8000/metrics
```

## Advanced Configurations

### Network Policy

NetworkPolicy restricts traffic to:
- Ingress: Only from ingress controller and weather-tracker pods
- Egress: Only to Redis, DNS, and external APIs

Modify `redis-deployment.yaml` NetworkPolicy to allow/deny specific traffic.

### Pod Disruption Budget

Ensures minimum 2 pods available during node maintenance:
```yaml
minAvailable: 2
```

### Resource Quotas

Namespace limited to:
- CPU: 2 cores
- Memory: 2Gi
- Pods: 20

Increase in `redis-deployment.yaml` ResourceQuota if needed.

## Cleanup

Delete all resources:
```bash
# Delete application
kubectl delete namespace weather-tracker

# This removes:
# - Deployment
# - Service
# - ConfigMaps
# - Secrets
# - StatefulSet
# - PersistentVolumeClaims
# - NetworkPolicy
# - etc.
```

Note: Deleting PVC may also delete EBS volume (check VolumeBindingMode).

## Integration Examples

### CI/CD Pipeline

```bash
# Update image and redeploy
docker build -t weather-tracker:$GIT_SHA .
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:$GIT_SHA

kubectl set image deployment/weather-tracker-api \
  api=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:$GIT_SHA \
  -n weather-tracker
```

### GitOps with ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create ArgoCD Application
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: weather-tracker
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-repo
    targetRevision: HEAD
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: weather-tracker
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## Performance Tuning

### API Optimization
```yaml
WORKERS: "8"  # More workers for higher throughput
CACHE_TTL: "7200"  # Longer cache for less API calls
```

### Redis Optimization
```conf
maxmemory-policy allkeys-lru  # Evict LRU keys when full
appendonly yes  # Enable AOF for durability (slower)
```

### Node Sizing
```bash
# Scale up to more powerful instances
terraform apply -var="node_instance_types=[\"t3.xlarge\"]"
```

## Support & Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Objects Guide](https://kubernetes.io/docs/concepts/overview/)
