#!/bin/bash
set -e

echo "=========================================="
echo "Fixing Docker and Pushing Backend Image"
echo "=========================================="
echo ""

# Step 1: Check Docker
echo "🔍 Step 1: Checking Docker status..."
if ! docker ps > /dev/null 2>&1; then
  echo "❌ Docker daemon is not responding"
  echo ""
  echo "💡 Try these solutions:"
  echo ""
  echo "Option 1: Restart Docker Desktop"
  echo "   - Close Docker Desktop completely"
  echo "   - Restart Docker Desktop"
  echo "   - Wait for it to fully start"
  echo ""
  echo "Option 2: Restart Docker service (if using systemd)"
  echo "   sudo systemctl restart docker"
  echo ""
  echo "Option 3: Check Docker socket"
  echo "   ls -la ~/.docker/desktop/docker.sock"
  echo ""
  read -p "Press Enter after you've restarted Docker, or Ctrl+C to exit..."
fi

# Step 2: Test Docker
echo ""
echo "🧪 Step 2: Testing Docker..."
docker ps > /dev/null 2>&1 || {
  echo "❌ Docker still not working. Please restart Docker and try again."
  exit 1
}
echo "✅ Docker is working!"

# Step 3: Configuration
REGION="us-west-1"
ACCOUNT_ID="121577249019"
REPO_NAME="cardinal-backend-prod"
IMAGE_TAG="latest"
BACKEND_DIR="/home/gwl/Documents/OB_backend"

# Step 4: Authenticate with ECR
echo ""
echo "🔐 Step 4: Authenticating with ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com || {
    echo "❌ ECR authentication failed"
    echo "💡 Check:"
    echo "   1. AWS credentials are configured"
    echo "   2. You have permissions to push to ECR"
    echo "   3. Region is correct: $REGION"
    exit 1
  }
echo "✅ ECR authentication successful!"

# Step 5: Check if image exists locally
echo ""
echo "🔍 Step 5: Checking local image..."
if docker images | grep -q "${REPO_NAME}.*${IMAGE_TAG}"; then
  echo "✅ Found local image, reusing..."
  docker tag ${REPO_NAME}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG} 2>/dev/null || {
    echo "⚠️  Tagging failed, will rebuild..."
    cd "$BACKEND_DIR"
    docker build -t ${REPO_NAME}:${IMAGE_TAG} .
    docker tag ${REPO_NAME}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
  }
else
  echo "📦 Building image from $BACKEND_DIR..."
  cd "$BACKEND_DIR"
  docker build -t ${REPO_NAME}:${IMAGE_TAG} . || {
    echo "❌ Build failed"
    exit 1
  }
  docker tag ${REPO_NAME}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
fi

# Step 6: Show image info
echo ""
echo "📊 Image info:"
docker images ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Step 7: Push to ECR
echo ""
echo "🚀 Step 7: Pushing to ECR..."
echo "   This may take a few minutes depending on image size and network speed..."
echo "   Repository: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
echo ""

# Push with progress (no timeout, but we'll monitor)
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG} || {
  echo ""
  echo "❌ Push failed"
  echo "💡 Troubleshooting:"
  echo "   1. Check internet connection"
  echo "   2. Verify ECR repository exists: aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION"
  echo "   3. Check AWS credentials: aws sts get-caller-identity"
  echo "   4. Try pushing again"
  exit 1
}

echo ""
echo "=========================================="
echo "✅ Image pushed successfully!"
echo "=========================================="

# Step 8: Verify
echo ""
echo "🔍 Step 8: Verifying in ECR..."
aws ecr describe-images \
  --repository-name ${REPO_NAME} \
  --region ${REGION} \
  --image-ids imageTag=${IMAGE_TAG} \
  --query 'imageDetails[0].{PushedAt:imagePushedAt,Size:imageSizeInBytes,Tags:imageTags}' \
  --output table 2>/dev/null || {
    echo "⚠️  Could not verify, but push may have succeeded"
  }

# Step 9: Deploy
echo ""
echo "🔄 Step 9: Deploying to ECS..."
read -p "Force new ECS deployment? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  aws ecs update-service \
    --cluster cardinal-prod-cluster \
    --service cardinal-prod-backend-service \
    --force-new-deployment \
    --region $REGION \
    --query 'service.{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,TaskDefinition:taskDefinition}' \
    --output table
  
  echo ""
  echo "⏳ Deployment initiated!"
  echo "   Monitor: aws ecs describe-services --cluster cardinal-prod-cluster --services cardinal-prod-backend-service --region $REGION"
fi

echo ""
echo "✅ All done!"


