# ECS Services Deployment Process

## Current Situation
- ✅ Terraform apply completed successfully
- ✅ ECR repositories created (`cardinal-frontend`, `cardinal-backend`)
- ✅ ECS services created but failing (0 tasks running)
- ❌ ECR repositories are empty (no images pushed)
- ❌ Services can't pull images because they don't exist

## Deployment Steps

### Step 1: Push Images to ECR

**Option A: Using the provided script**
```bash
# Make script executable
chmod +x push-images-to-ecr.sh

# Run the script (you need to provide source images)
./push-images-to-ecr.sh <source-frontend-image> <source-backend-image>
```

**Option B: Manual push**
```bash
# Login to ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin \
  121577249019.dkr.ecr.us-west-2.amazonaws.com

# Tag your images
docker tag <your-frontend-image> \
  121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:develop-e86163776efc6e31edf1d8cb642a56288418959d

docker tag <your-backend-image> \
  121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:develop-e86163776efc6e31edf1d8cb642a56288418959d

# Push to ECR
docker push 121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:develop-e86163776efc6e31edf1d8cb642a56288418959d
docker push 121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:develop-e86163776efc6e31edf1d8cb642a56288418959d
```

### Step 2: Update ECS Services

After images are pushed, you have **two options**:

#### Option A: Force New Deployment (Recommended - Faster)

1. Go to **ECS Console** → **Clusters** → `cardinal-prod-usw2-cluster` → **Services**
2. Select each service:
   - `cardinal-prod-usw2-frontend-service`
   - `cardinal-prod-usw2-backend-service`
3. Click **"Update"** button
4. Click **"Force new deployment"**
5. Click **"Update"**

This will:
- Use the existing task definition (which already has the correct image URI)
- Force ECS to pull the image again
- Deploy new tasks

#### Option B: Run Terraform Apply Again (Slower)

1. Run `terraform apply` again
2. Terraform will create new task definitions with correct image URIs
3. **BUT** - The service has `ignore_changes = [task_definition]`, so it won't automatically update
4. You'll still need to manually force deployment (as in Option A)

### Step 3: Verify Deployment

1. Check ECS Services:
   - Tasks should start running
   - Health checks should pass
   - Status should be "Running"

2. Check ALB Target Groups:
   - Targets should be healthy
   - Health check status should be "healthy"

3. Access Application:
   - Get ALB DNS name from AWS Console or Terraform outputs
   - Access: `http://<ALB-DNS-NAME>`

## Why Services Aren't Deploying

The services are failing because:
1. **Images don't exist in ECR** - ECS can't pull them
2. **Task definitions reference images that don't exist** - Tasks fail immediately
3. **Services are in "Failed" state** - Waiting for valid images

## Quick Fix Summary

```bash
# 1. Push images to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 121577249019.dkr.ecr.us-west-2.amazonaws.com
docker tag <frontend-image> 121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:develop-e86163776efc6e31edf1d8cb642a56288418959d
docker tag <backend-image> 121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:develop-e86163776efc6e31edf1d8cb642a56288418959d
docker push 121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:develop-e86163776efc6e31edf1d8cb642a56288418959d
docker push 121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:develop-e86163776efc6e31edf1d8cb642a56288418959d

# 2. Force new deployment in ECS Console
# OR use AWS CLI:
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-frontend-service \
  --force-new-deployment \
  --region us-west-2

aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-backend-service \
  --force-new-deployment \
  --region us-west-2
```

## After Deployment

Once images are pushed and services are updated:
- ✅ Tasks will start running
- ✅ Health checks will pass
- ✅ Application will be accessible via ALB DNS
- ✅ Services will be healthy




