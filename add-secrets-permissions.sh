#!/bin/bash
# Script to add Secrets Manager permissions to ECS task execution roles
# This fixes the AccessDeniedException when ECS tries to pull secrets

set -euo pipefail

AWS_REGION="us-west-2"
ACCOUNT_ID="121577249019"
SECRET_ARN_PATTERN="arn:aws:secretsmanager:${AWS_REGION}:${ACCOUNT_ID}:secret:cardinal/prod-usw2/db-*"

FRONTEND_ROLE="cardinal-prod-usw2-frontend-task-exec"
BACKEND_ROLE="cardinal-prod-usw2-backend-task-exec"

FRONTEND_POLICY_NAME="cardinal-prod-usw2-frontend-exec-secrets"
BACKEND_POLICY_NAME="cardinal-prod-usw2-backend-exec-secrets"

FRONTEND_POLICY_FILE="frontend-exec-secrets-policy.json"
BACKEND_POLICY_FILE="backend-exec-secrets-policy.json"

echo "=========================================="
echo "Adding Secrets Manager Permissions"
echo "=========================================="
echo "Region: ${AWS_REGION}"
echo "Secret ARN Pattern: ${SECRET_ARN_PATTERN}"
echo ""

# Check if policy files exist
if [ ! -f "${FRONTEND_POLICY_FILE}" ]; then
  echo "Error: ${FRONTEND_POLICY_FILE} not found!"
  exit 1
fi

if [ ! -f "${BACKEND_POLICY_FILE}" ]; then
  echo "Error: ${BACKEND_POLICY_FILE} not found!"
  exit 1
fi

# Add policy to frontend execution role
echo "Step 1: Adding policy to ${FRONTEND_ROLE}..."
aws iam put-role-policy \
  --role-name "${FRONTEND_ROLE}" \
  --policy-name "${FRONTEND_POLICY_NAME}" \
  --policy-document "file://${FRONTEND_POLICY_FILE}" \
  --region "${AWS_REGION}"

if [ $? -eq 0 ]; then
  echo "✅ Successfully added policy to ${FRONTEND_ROLE}"
else
  echo "❌ Failed to add policy to ${FRONTEND_ROLE}"
  exit 1
fi

echo ""

# Add policy to backend execution role
echo "Step 2: Adding policy to ${BACKEND_ROLE}..."
aws iam put-role-policy \
  --role-name "${BACKEND_ROLE}" \
  --policy-name "${BACKEND_POLICY_NAME}" \
  --policy-document "file://${BACKEND_POLICY_FILE}" \
  --region "${AWS_REGION}"

if [ $? -eq 0 ]; then
  echo "✅ Successfully added policy to ${BACKEND_ROLE}"
else
  echo "❌ Failed to add policy to ${BACKEND_ROLE}"
  exit 1
fi

echo ""
echo "=========================================="
echo "✅ Permissions added successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Force new deployment of ECS services:"
echo ""
echo "   aws ecs update-service \\"
echo "     --cluster cardinal-prod-usw2-cluster \\"
echo "     --service cardinal-prod-usw2-frontend-service \\"
echo "     --force-new-deployment \\"
echo "     --region us-west-2"
echo ""
echo "   aws ecs update-service \\"
echo "     --cluster cardinal-prod-usw2-cluster \\"
echo "     --service cardinal-prod-usw2-backend-service \\"
echo "     --force-new-deployment \\"
echo "     --region us-west-2"
echo ""
echo "2. Monitor ECS tasks in AWS Console to verify they start successfully"
echo ""




