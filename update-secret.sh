#!/bin/bash
# Script to update Secrets Manager secret with correct structure

set -euo pipefail

REGION="us-west-2"
SECRET_ID="cardinal/prod-usw2/db"

echo "=========================================="
echo "Updating Secrets Manager Secret"
echo "=========================================="
echo "Secret: ${SECRET_ID}"
echo "Region: ${REGION}"
echo ""

# Get current secret
echo "Step 1: Retrieving current secret..."
CURRENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ID}" \
  --region "${REGION}" \
  --query 'SecretString' \
  --output text 2>/dev/null || echo "{}")

if [ "${CURRENT_SECRET}" = "{}" ]; then
  echo "⚠️  Secret not found or empty. You may need to create it first."
  exit 1
fi

# Extract values
PASSWORD=$(echo "${CURRENT_SECRET}" | jq -r '.password // empty')
USERNAME=$(echo "${CURRENT_SECRET}" | jq -r '.username // "cardinalproddb"')

if [ -z "${PASSWORD}" ]; then
  echo "❌ Error: Could not extract password from secret"
  echo "Current secret: ${CURRENT_SECRET}"
  exit 1
fi

echo "✅ Retrieved password and username"

# Get RDS endpoint
echo ""
echo "Step 2: Retrieving RDS endpoint..."
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --region "${REGION}" \
  --db-instance-identifier cardinal-prod-usw2-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text 2>/dev/null || echo "")

if [ -z "${RDS_ENDPOINT}" ]; then
  echo "⚠️  RDS instance not found. Using placeholder endpoint."
  RDS_ENDPOINT="cardinal-prod-usw2-db.placeholder.us-west-2.rds.amazonaws.com"
fi

RDS_PORT=$(aws rds describe-db-instances \
  --region "${REGION}" \
  --db-instance-identifier cardinal-prod-usw2-db \
  --query 'DBInstances[0].Endpoint.Port' \
  --output text 2>/dev/null || echo "5432")

echo "✅ RDS Endpoint: ${RDS_ENDPOINT}"
echo "✅ RDS Port: ${RDS_PORT}"

# Update secret
echo ""
echo "Step 3: Updating secret with correct structure..."
aws secretsmanager put-secret-value \
  --secret-id "${SECRET_ID}" \
  --region "${REGION}" \
  --secret-string "{
    \"username\": \"${USERNAME}\",
    \"password\": \"${PASSWORD}\",
    \"host\": \"${RDS_ENDPOINT}\",
    \"port\": ${RDS_PORT},
    \"database\": \"cardinal_prod_usw2\"
  }" > /dev/null

if [ $? -eq 0 ]; then
  echo "✅ Secret updated successfully!"
else
  echo "❌ Failed to update secret"
  exit 1
fi

echo ""
echo "=========================================="
echo "✅ Secret Update Complete!"
echo "=========================================="
echo ""
echo "Next step: Force new deployment of ECS services"
echo ""
echo "aws ecs update-service \\"
echo "  --cluster cardinal-prod-usw2-cluster \\"
echo "  --service cardinal-prod-usw2-frontend-service \\"
echo "  --force-new-deployment \\"
echo "  --region us-west-2"
echo ""
echo "aws ecs update-service \\"
echo "  --cluster cardinal-prod-usw2-cluster \\"
echo "  --service cardinal-prod-usw2-backend-service \\"
echo "  --force-new-deployment \\"
echo "  --region us-west-2"
