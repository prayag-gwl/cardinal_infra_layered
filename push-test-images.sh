#!/bin/bash
# Quick script to push test images (nginx) to ECR for infrastructure testing
# This allows you to test the infrastructure while you build your actual images later

set -euo pipefail

AWS_REGION="us-west-2"
AWS_ACCOUNT_ID="121577249019"
FRONTEND_TAG="develop-e86163776efc6e31edf1d8cb642a56288418959d"
BACKEND_TAG="develop-e86163776efc6e31edf1d8cb642a56288418959d"

FRONTEND_ECR="121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:${FRONTEND_TAG}"
BACKEND_ECR="121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:${BACKEND_TAG}"

echo "=========================================="
echo "Pushing Test Images to ECR"
echo "=========================================="
echo "Using nginx:latest as test image"
echo "Frontend: ${FRONTEND_ECR}"
echo "Backend:  ${BACKEND_ECR}"
echo ""
echo "⚠️  NOTE: These are test images. Replace with your actual images later."
echo ""

# Login to ECR
echo "Step 1: Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Pull nginx (if not already local)
echo ""
echo "Step 2: Pulling nginx:latest..."
docker pull nginx:latest

# Tag for ECR
echo ""
echo "Step 3: Tagging images..."
docker tag nginx:latest "${FRONTEND_ECR}"
docker tag nginx:latest "${BACKEND_ECR}"

# Push to ECR
echo ""
echo "Step 4: Pushing to ECR..."
docker push "${FRONTEND_ECR}"
docker push "${BACKEND_ECR}"

echo ""
echo "=========================================="
echo "✅ Test images pushed successfully!"
echo "=========================================="
echo "Frontend: ${FRONTEND_ECR}"
echo "Backend:  ${BACKEND_ECR}"
echo ""
echo "Next steps:"
echo "1. Force new deployment in ECS Console:"
echo "   - Go to ECS → Clusters → cardinal-prod-usw2-cluster → Services"
echo "   - Select each service → Update → Force new deployment"
echo ""
echo "2. Or use AWS CLI:"
echo "   aws ecs update-service --cluster cardinal-prod-usw2-cluster --service cardinal-prod-usw2-frontend-service --force-new-deployment --region us-west-2"
echo "   aws ecs update-service --cluster cardinal-prod-usw2-cluster --service cardinal-prod-usw2-backend-service --force-new-deployment --region us-west-2"
echo ""
echo "3. Once your actual images are ready, push them with the same tags to replace these test images."




