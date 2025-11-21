#!/bin/bash
# Simple script to push images to ECR
# Usage: ./push-images-simple.sh <source-frontend-image> <source-backend-image>

set -euo pipefail

AWS_REGION="us-west-2"
AWS_ACCOUNT_ID="121577249019"
FRONTEND_TAG="develop-e86163776efc6e31edf1d8cb642a56288418959d"
BACKEND_TAG="develop-e86163776efc6e31edf1d8cb642a56288418959d"

FRONTEND_SOURCE="${1:-}"
BACKEND_SOURCE="${2:-}"

if [ -z "$FRONTEND_SOURCE" ] || [ -z "$BACKEND_SOURCE" ]; then
  echo "Usage: $0 <source-frontend-image> <source-backend-image>"
  echo ""
  echo "Examples:"
  echo "  $0 my-frontend:latest my-backend:latest"
  echo "  $0 123456789012.dkr.ecr.us-east-1.amazonaws.com/cardinal-frontend:tag1 123456789012.dkr.ecr.us-east-1.amazonaws.com/cardinal-backend:tag2"
  exit 1
fi

FRONTEND_ECR="121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:${FRONTEND_TAG}"
BACKEND_ECR="121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:${BACKEND_TAG}"

echo "=========================================="
echo "Pushing Images to ECR"
echo "=========================================="
echo "Frontend: ${FRONTEND_SOURCE} -> ${FRONTEND_ECR}"
echo "Backend:  ${BACKEND_SOURCE} -> ${BACKEND_ECR}"
echo ""

# Login to ECR
echo "Step 1: Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Pull source images if they're from a registry
if [[ "$FRONTEND_SOURCE" == *"dkr.ecr"* ]] || [[ "$FRONTEND_SOURCE" == *"docker.io"* ]] || [[ "$FRONTEND_SOURCE" == *"gcr.io"* ]]; then
  echo ""
  echo "Pulling source images..."
  docker pull "${FRONTEND_SOURCE}" || echo "Warning: Could not pull ${FRONTEND_SOURCE}"
  docker pull "${BACKEND_SOURCE}" || echo "Warning: Could not pull ${BACKEND_SOURCE}"
fi

# Tag images
echo ""
echo "Step 2: Tagging images..."
docker tag "${FRONTEND_SOURCE}" "${FRONTEND_ECR}"
docker tag "${BACKEND_SOURCE}" "${BACKEND_ECR}"

# Push images
echo ""
echo "Step 3: Pushing to ECR..."
docker push "${FRONTEND_ECR}"
docker push "${BACKEND_ECR}"

echo ""
echo "=========================================="
echo "✅ Images pushed successfully!"
echo "=========================================="
echo "Frontend: ${FRONTEND_ECR}"
echo "Backend:  ${BACKEND_ECR}"
echo ""
echo "Next step: Force new deployment in ECS Console or run:"
echo "  aws ecs update-service --cluster cardinal-prod-usw2-cluster --service cardinal-prod-usw2-frontend-service --force-new-deployment --region us-west-2"
echo "  aws ecs update-service --cluster cardinal-prod-usw2-cluster --service cardinal-prod-usw2-backend-service --force-new-deployment --region us-west-2"




