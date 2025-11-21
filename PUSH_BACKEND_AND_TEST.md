# Push Backend Image and Test Application

This guide helps you push the backend Docker image to ECR and test if the application is accessible.

## Prerequisites

1. ✅ Terraform apply completed (infrastructure is deployed)
2. ✅ ECR repositories created: `cardinal-frontend-prod` and `cardinal-backend-prod`
3. ✅ ECS services are running
4. ✅ ALBs are created and healthy

## Step 1: Get ECR Repository URLs

From the Terraform outputs or AWS Console, get the ECR repository URLs:

**Backend Repository**: `121577249019.dkr.ecr.us-west-1.amazonaws.com/cardinal-backend-prod`  
**Frontend Repository**: `121577249019.dkr.ecr.us-west-1.amazonaws.com/cardinal-frontend-prod`

Or get them via AWS CLI:
```bash
aws ecr describe-repositories --region us-west-1 --repository-names cardinal-backend-prod cardinal-frontend-prod --query 'repositories[*].repositoryUri' --output text
```

## Step 2: Authenticate Docker with ECR

```bash
aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 121577249019.dkr.ecr.us-west-1.amazonaws.com
```

## Step 3: Build and Tag Backend Image

If you have a Dockerfile for the backend:

```bash
# Navigate to your backend directory
cd /path/to/your/backend

# Build the image
docker build -t cardinal-backend:latest .

# Tag for ECR
docker tag cardinal-backend:latest 121577249019.dkr.ecr.us-west-1.amazonaws.com/cardinal-backend-prod:latest
```

Or if you want to use an existing image:

```bash
# Pull existing image (if from another registry)
docker pull your-registry/cardinal-backend:latest

# Tag for ECR
docker tag your-registry/cardinal-backend:latest 121577249019.dkr.ecr.us-west-1.amazonaws.com/cardinal-backend-prod:latest
```

## Step 4: Push Backend Image to ECR

```bash
docker push 121577249019.dkr.ecr.us-west-1.amazonaws.com/cardinal-backend-prod:latest
```

## Step 5: Update ECS Service to Use New Image

### Option A: Update via Terraform (Recommended)

Update the `backend_image` variable in GitHub Actions or update `stacks/prod/main.tf`:

```terraform
backend_image = "121577249019.dkr.ecr.us-west-1.amazonaws.com/cardinal-backend-prod:latest"
```

Then run Terraform apply to update the task definition.

### Option B: Force New Deployment via AWS Console

1. Go to **ECS** → **Clusters** → `cardinal-prod-cluster`
2. Click on **Services** → `cardinal-prod-backend-service`
3. Click **Update**
4. Check **Force new deployment**
5. Click **Update**

This will create a new task definition with the latest image tag.

### Option C: Update via AWS CLI

```bash
# Force new deployment
aws ecs update-service \
  --cluster cardinal-prod-cluster \
  --service cardinal-prod-backend-service \
  --force-new-deployment \
  --region us-west-1
```

## Step 6: Get ALB DNS Names

Get the ALB endpoints:

```bash
# Frontend ALB (Public)
aws elbv2 describe-load-balancers \
  --region us-west-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `frontend`)].DNSName' \
  --output text

# Backend ALB (Internal)
aws elbv2 describe-load-balancers \
  --region us-west-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `backend`)].DNSName' \
  --output text
```

Or from Terraform outputs (if configured):
```bash
cd stacks/prod
terraform output
```

## Step 7: Test Backend Health Endpoint

Wait for the service to stabilize (2-3 minutes), then test:

```bash
# Get backend ALB DNS
BACKEND_ALB=$(aws elbv2 describe-load-balancers \
  --region us-west-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `backend`)].DNSName' \
  --output text)

# Test health endpoint (adjust path based on your app)
curl -v http://${BACKEND_ALB}/api/cardinal-education-service/v1/health
# or
curl -v http://${BACKEND_ALB}/health
```

## Step 8: Check ECS Service Status

```bash
# Check service status
aws ecs describe-services \
  --cluster cardinal-prod-cluster \
  --services cardinal-prod-backend-service \
  --region us-west-1 \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Deployments:deployments[*].{Status:status,TaskDef:taskDefinition}}'

# Check running tasks
aws ecs list-tasks \
  --cluster cardinal-prod-cluster \
  --service-name cardinal-prod-backend-service \
  --region us-west-1

# Get task details
TASK_ARN=$(aws ecs list-tasks \
  --cluster cardinal-prod-cluster \
  --service-name cardinal-prod-backend-service \
  --region us-west-1 \
  --query 'taskArns[0]' --output text)

aws ecs describe-tasks \
  --cluster cardinal-prod-cluster \
  --tasks $TASK_ARN \
  --region us-west-1 \
  --query 'tasks[0].{LastStatus:lastStatus,HealthStatus:healthStatus,StoppedReason:stoppedReason}'
```

## Step 9: Check CloudWatch Logs

If the service isn't working, check the logs:

```bash
# Get recent logs
aws logs tail /ecs/cardinal-prod-backend \
  --region us-west-1 \
  --follow \
  --since 10m
```

## Step 10: Test Frontend (if available)

If you also push the frontend image:

```bash
# Get frontend ALB DNS
FRONTEND_ALB=$(aws elbv2 describe-load-balancers \
  --region us-west-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `frontend`)].DNSName' \
  --output text)

# Test frontend
curl -v http://${FRONTEND_ALB}/
curl -v http://${FRONTEND_ALB}/health
```

## Troubleshooting

### Service Not Starting

1. **Check task status**:
   ```bash
   aws ecs describe-tasks \
     --cluster cardinal-prod-cluster \
     --tasks <TASK_ARN> \
     --region us-west-1
   ```

2. **Check CloudWatch Logs** for errors

3. **Check Secrets Manager** - Ensure secrets are accessible:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id cardinal/db-creds-JJ2qN4 \
     --region us-west-1
   ```

### Health Check Failing

1. **Verify health check path** matches your application
2. **Check container logs** for application errors
3. **Verify port 3000** is correct for your app
4. **Check security groups** allow traffic on port 3000

### Image Pull Errors

1. **Verify ECR authentication**:
   ```bash
   aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 121577249019.dkr.ecr.us-west-1.amazonaws.com
   ```

2. **Check image exists**:
   ```bash
   aws ecr describe-images \
     --repository-name cardinal-backend-prod \
     --region us-west-1
   ```

3. **Verify IAM permissions** - Execution role needs ECR pull permissions

## Quick Test Script

Save this as `test-backend.sh`:

```bash
#!/bin/bash
set -e

REGION="us-west-1"
CLUSTER="cardinal-prod-cluster"
SERVICE="cardinal-prod-backend-service"

echo "🔍 Checking ECS service status..."
aws ecs describe-services \
  --cluster $CLUSTER \
  --services $SERVICE \
  --region $REGION \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}' \
  --output table

echo ""
echo "🌐 Getting Backend ALB DNS..."
BACKEND_ALB=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --query 'LoadBalancers[?contains(LoadBalancerName, `backend`)].DNSName' \
  --output text)

echo "Backend ALB: $BACKEND_ALB"
echo ""
echo "🏥 Testing health endpoint..."
curl -f http://${BACKEND_ALB}/health || curl -f http://${BACKEND_ALB}/api/cardinal-education-service/v1/health || echo "Health check failed - check logs"

echo ""
echo "✅ Test complete!"
```

Make it executable and run:
```bash
chmod +x test-backend.sh
./test-backend.sh
```

## Next Steps

Once backend is working:
1. ✅ Push frontend image
2. ✅ Update frontend service
3. ✅ Test full application flow
4. ✅ Fix backup plan issue (optional, can be done later)


