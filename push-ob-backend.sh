#!/bin/bash
set -e

# Configuration
REGION="us-west-1"
ACCOUNT_ID="121577249019"
REPO_NAME="cardinal-backend-prod"
IMAGE_TAG="latest"
BACKEND_DIR="/home/gwl/Documents/OB_backend"

echo "=========================================="
echo "Building and Pushing OB_backend Image"
echo "=========================================="
echo "Backend Directory: $BACKEND_DIR"
echo "ECR Repository: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
echo ""

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
  echo "❌ Error: Backend directory not found: $BACKEND_DIR"
  exit 1
fi

# Check for Dockerfile
if [ ! -f "$BACKEND_DIR/Dockerfile" ]; then
  echo "⚠️  Warning: No Dockerfile found in $BACKEND_DIR"
  echo "Please ensure you have a Dockerfile in the backend directory"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Step 1: Authenticate Docker with ECR
echo "🔐 Step 1: Authenticating Docker with ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Step 2: Build the image
echo ""
echo "📦 Step 2: Building Docker image from $BACKEND_DIR..."
cd "$BACKEND_DIR"
docker build -t ${REPO_NAME}:${IMAGE_TAG} .

# Step 3: Tag for ECR
echo ""
echo "🏷️  Step 3: Tagging image for ECR..."
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}

# Step 4: Push to ECR
echo ""
echo "🚀 Step 4: Pushing image to ECR..."
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}

echo ""
echo "=========================================="
echo "✅ Image pushed successfully!"
echo "=========================================="
echo "Image: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
echo ""
echo "🔄 Next: Force new ECS deployment..."
echo ""

# Step 5: Force new deployment
read -p "Force new ECS deployment now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  echo "🔄 Forcing new ECS deployment..."
  aws ecs update-service \
    --cluster cardinal-prod-cluster \
    --service cardinal-prod-backend-service \
    --force-new-deployment \
    --region $REGION \
    --query 'service.{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,TaskDefinition:taskDefinition}' \
    --output table
  
  echo ""
  echo "⏳ Deployment initiated. It may take 2-3 minutes for tasks to start."
  echo ""
  echo "📊 Monitor deployment:"
  echo "  aws ecs describe-services --cluster cardinal-prod-cluster --services cardinal-prod-backend-service --region $REGION"
  echo ""
  echo "🌐 Get ALB DNS:"
  echo "  aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerName, \`backend\`)].DNSName' --output text"
fi

echo ""
echo "✅ Done!"


