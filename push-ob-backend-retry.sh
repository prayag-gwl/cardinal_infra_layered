#!/bin/bash
set -e

# Configuration
REGION="us-west-1"
ACCOUNT_ID="121577249019"
REPO_NAME="cardinal-backend-prod"
IMAGE_TAG="latest"
BACKEND_DIR="/home/gwl/Documents/OB_backend"

echo "=========================================="
echo "Retrying: Building and Pushing OB_backend"
echo "=========================================="
echo ""

# Step 1: Authenticate (refresh token)
echo "🔐 Step 1: Refreshing ECR authentication..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com || {
    echo "❌ ECR authentication failed"
    exit 1
  }

# Step 2: Check if image already exists locally
echo ""
echo "🔍 Checking local image..."
if docker images | grep -q "${REPO_NAME}.*${IMAGE_TAG}"; then
  echo "✅ Local image found, reusing..."
  docker tag ${REPO_NAME}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
else
  echo "📦 Building new image from $BACKEND_DIR..."
  cd "$BACKEND_DIR"
  docker build -t ${REPO_NAME}:${IMAGE_TAG} . || {
    echo "❌ Build failed"
    exit 1
  }
  docker tag ${REPO_NAME}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
fi

# Step 3: Check image size
echo ""
echo "📊 Image size:"
docker images ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Step 4: Push with progress
echo ""
echo "🚀 Step 4: Pushing to ECR (this may take a few minutes)..."
echo "   Repository: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
echo ""

# Push with timeout and progress monitoring
timeout 600 docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG} || {
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 124 ]; then
    echo ""
    echo "⏱️  Push timed out after 10 minutes"
    echo "💡 Try:"
    echo "   1. Check your internet connection"
    echo "   2. Try pushing again (image is already built)"
    echo "   3. Check AWS service status"
    exit 1
  else
    echo ""
    echo "❌ Push failed with exit code: $EXIT_CODE"
    exit 1
  fi
}

echo ""
echo "=========================================="
echo "✅ Image pushed successfully!"
echo "=========================================="

# Step 5: Verify in ECR
echo ""
echo "🔍 Verifying image in ECR..."
aws ecr describe-images \
  --repository-name ${REPO_NAME} \
  --region ${REGION} \
  --image-ids imageTag=${IMAGE_TAG} \
  --query 'imageDetails[0].{PushedAt:imagePushedAt,Size:imageSizeInBytes,Tags:imageTags}' \
  --output table || {
    echo "⚠️  Could not verify in ECR, but push may have succeeded"
  }

echo ""
echo "🔄 Next: Force new ECS deployment..."
read -p "Force new deployment now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  aws ecs update-service \
    --cluster cardinal-prod-cluster \
    --service cardinal-prod-backend-service \
    --force-new-deployment \
    --region $REGION \
    --query 'service.{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}' \
    --output table
  
  echo ""
  echo "⏳ Deployment initiated. Monitor with:"
  echo "   aws ecs describe-services --cluster cardinal-prod-cluster --services cardinal-prod-backend-service --region $REGION"
fi

echo ""
echo "✅ Done!"


