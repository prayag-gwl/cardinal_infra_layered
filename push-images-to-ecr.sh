#!/bin/bash
# Script to push Docker images to ECR repositories
# Usage: ./push-images-to-ecr.sh <frontend-image-tag> <backend-image-tag>

set -euo pipefail

# Configuration
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID="121577249019"
PROJECT="cardinal"
FRONTEND_REPO="${PROJECT}-frontend"
BACKEND_REPO="${PROJECT}-backend"

# Get image tags from arguments or use defaults
FRONTEND_TAG="${1:-develop-e86163776efc6e31edf1d8cb642a56288418959d}"
BACKEND_TAG="${2:-develop-e86163776efc6e31edf1d8cb642a56288418959d}"

echo "=========================================="
echo "Pushing Docker images to ECR"
echo "=========================================="
echo "Region: ${AWS_REGION}"
echo "Account: ${AWS_ACCOUNT_ID}"
echo "Frontend Tag: ${FRONTEND_TAG}"
echo "Backend Tag: ${BACKEND_TAG}"
echo ""

# Login to ECR
echo "Step 1: Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# ECR Repository URIs
FRONTEND_ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${FRONTEND_TAG}"
BACKEND_ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${BACKEND_TAG}"

# Function to push image
push_image() {
    local SOURCE_IMAGE=$1
    local TARGET_ECR_URI=$2
    local IMAGE_NAME=$3
    
    echo ""
    echo "=========================================="
    echo "Pushing ${IMAGE_NAME}"
    echo "=========================================="
    echo "Source: ${SOURCE_IMAGE}"
    echo "Target: ${TARGET_ECR_URI}"
    
    # Check if source image exists locally
    if ! docker image inspect "${SOURCE_IMAGE}" &>/dev/null; then
        echo "ERROR: Image ${SOURCE_IMAGE} not found locally!"
        echo "Please build or pull the image first."
        echo ""
        echo "To build:"
        echo "  docker build -t ${SOURCE_IMAGE} <path-to-dockerfile>"
        echo ""
        echo "Or if image exists elsewhere, pull it:"
        echo "  docker pull ${SOURCE_IMAGE}"
        return 1
    fi
    
    # Tag the image for ECR
    echo "Tagging image..."
    docker tag "${SOURCE_IMAGE}" "${TARGET_ECR_URI}"
    
    # Push to ECR
    echo "Pushing to ECR..."
    docker push "${TARGET_ECR_URI}"
    
    echo "✅ Successfully pushed ${IMAGE_NAME}"
}

# Check if images are provided as full URIs or just tags
if [[ "${FRONTEND_TAG}" == *"dkr.ecr"* ]] || [[ "${FRONTEND_TAG}" == *":"* ]]; then
    # Full image URI provided
    FRONTEND_SOURCE="${FRONTEND_TAG}"
    FRONTEND_TAG_ONLY=$(echo "${FRONTEND_TAG}" | cut -d':' -f2)
    FRONTEND_ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${FRONTEND_TAG_ONLY}"
else
    # Just tag provided - need source image
    echo "ERROR: Please provide source Docker images."
    echo ""
    echo "Option 1: Provide full source image URIs:"
    echo "  ./push-images-to-ecr.sh <source-frontend-image> <source-backend-image>"
    echo ""
    echo "Option 2: If images are already built locally with these tags:"
    echo "  docker tag <local-frontend-image> ${FRONTEND_ECR_URI}"
    echo "  docker tag <local-backend-image> ${BACKEND_ECR_URI}"
    echo "  docker push ${FRONTEND_ECR_URI}"
    echo "  docker push ${BACKEND_ECR_URI}"
    exit 1
fi

if [[ "${BACKEND_TAG}" == *"dkr.ecr"* ]] || [[ "${BACKEND_TAG}" == *":"* ]]; then
    BACKEND_SOURCE="${BACKEND_TAG}"
    BACKEND_TAG_ONLY=$(echo "${BACKEND_TAG}" | cut -d':' -f2)
    BACKEND_ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${BACKEND_TAG_ONLY}"
else
    echo "ERROR: Please provide source Docker images."
    exit 1
fi

# Push images
push_image "${FRONTEND_SOURCE}" "${FRONTEND_ECR_URI}" "Frontend"
push_image "${BACKEND_SOURCE}" "${BACKEND_ECR_URI}" "Backend"

echo ""
echo "=========================================="
echo "✅ All images pushed successfully!"
echo "=========================================="
echo "Frontend: ${FRONTEND_ECR_URI}"
echo "Backend: ${BACKEND_ECR_URI}"
echo ""
echo "You can now update the ECS services to use these images."




