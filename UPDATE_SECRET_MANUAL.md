# How to Update Secrets Manager Secret Manually

## Problem
The secret `cardinal/prod-usw2/db` is missing the `database` key. ECS expects these keys:
- `host` (not `endpoint`)
- `database` (currently missing)
- `username`
- `password`
- `port`

## Method 1: AWS Console (Easiest)

### Step 1: Get Current Secret Value
1. Go to **AWS Console** → **Secrets Manager**
2. Click on secret: `cardinal/prod-usw2/db`
3. Click **"Retrieve secret value"**
4. Note the current values (especially `password`)

### Step 2: Get RDS Endpoint
1. Go to **AWS Console** → **RDS** → **Databases**
2. Click on: `cardinal-prod-usw2-db`
3. Copy the **Endpoint** (e.g., `cardinal-prod-usw2-db.xxxxx.us-west-2.rds.amazonaws.com`)
4. Note the **Port** (usually `5432` for PostgreSQL)

### Step 3: Update Secret
1. Go back to **Secrets Manager** → `cardinal/prod-usw2/db`
2. Click **"Edit"**
3. In the **Secret value** field, replace the JSON with:

```json
{
  "username": "cardinalproddb",
  "password": "<paste-your-password-here>",
  "host": "<paste-rds-endpoint-here>",
  "port": 5432,
  "database": "cardinal_prod_usw2"
}
```

**Important:**
- Replace `<paste-your-password-here>` with the actual password from Step 1
- Replace `<paste-rds-endpoint-here>` with the RDS endpoint from Step 2
- Keep `database` as `cardinal_prod_usw2` (underscores, not hyphens)
- Keep `port` as `5432` (or whatever port your RDS uses)

4. Click **"Save"**

## Method 2: AWS CLI (Faster)

### Step 1: Get Current Secret
```bash
aws secretsmanager get-secret-value \
  --secret-id cardinal/prod-usw2/db \
  --region us-west-2 \
  --query 'SecretString' \
  --output text
```

### Step 2: Get RDS Endpoint
```bash
aws rds describe-db-instances \
  --region us-west-2 \
  --db-instance-identifier cardinal-prod-usw2-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### Step 3: Get RDS Port
```bash
aws rds describe-db-instances \
  --region us-west-2 \
  --db-instance-identifier cardinal-prod-usw2-db \
  --query 'DBInstances[0].Endpoint.Port' \
  --output text
```

### Step 4: Update Secret
```bash
# Replace <PASSWORD>, <RDS_ENDPOINT>, and <PORT> with actual values
aws secretsmanager put-secret-value \
  --secret-id cardinal/prod-usw2/db \
  --secret-string '{
    "username": "cardinalproddb",
    "password": "<PASSWORD>",
    "host": "<RDS_ENDPOINT>",
    "port": <PORT>,
    "database": "cardinal_prod_usw2"
  }' \
  --region us-west-2
```

**Example:**
```bash
aws secretsmanager put-secret-value \
  --secret-id cardinal/prod-usw2/db \
  --secret-string '{
    "username": "cardinalproddb",
    "password": "MySecurePassword123!",
    "host": "cardinal-prod-usw2-db.abc123.us-west-2.rds.amazonaws.com",
    "port": 5432,
    "database": "cardinal_prod_usw2"
  }' \
  --region us-west-2
```

## Method 3: One-Line Script

Save this script and run it (it will fetch values automatically):

```bash
#!/bin/bash
REGION="us-west-2"
SECRET_ID="cardinal/prod-usw2/db"

# Get current secret
CURRENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ID}" \
  --region "${REGION}" \
  --query 'SecretString' \
  --output text)

# Extract values
PASSWORD=$(echo "${CURRENT_SECRET}" | jq -r '.password')
USERNAME=$(echo "${CURRENT_SECRET}" | jq -r '.username // "cardinalproddb"')

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --region "${REGION}" \
  --db-instance-identifier cardinal-prod-usw2-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

RDS_PORT=$(aws rds describe-db-instances \
  --region "${REGION}" \
  --db-instance-identifier cardinal-prod-usw2-db \
  --query 'DBInstances[0].Endpoint.Port' \
  --output text)

# Update secret
aws secretsmanager put-secret-value \
  --secret-id "${SECRET_ID}" \
  --region "${REGION}" \
  --secret-string "{
    \"username\": \"${USERNAME}\",
    \"password\": \"${PASSWORD}\",
    \"host\": \"${RDS_ENDPOINT}\",
    \"port\": ${RDS_PORT},
    \"database\": \"cardinal_prod_usw2\"
  }"

echo "✅ Secret updated successfully!"
```

## After Updating Secret

**IMPORTANT:** Force a new deployment of ECS services:

```bash
# Frontend service
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-frontend-service \
  --force-new-deployment \
  --region us-west-2

# Backend service
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-backend-service \
  --force-new-deployment \
  --region us-west-2
```

Or via AWS Console:
1. ECS → Clusters → `cardinal-prod-usw2-cluster` → Services
2. Select each service → **Update** → Check **"Force new deployment"** → **Update**

## Verify Secret Structure

After updating, verify the secret has all required keys:

```bash
aws secretsmanager get-secret-value \
  --secret-id cardinal/prod-usw2/db \
  --region us-west-2 \
  --query 'SecretString' \
  --output text | jq .
```

You should see:
```json
{
  "username": "cardinalproddb",
  "password": "...",
  "host": "cardinal-prod-usw2-db.xxxxx.us-west-2.rds.amazonaws.com",
  "port": 5432,
  "database": "cardinal_prod_usw2"
}
```

## Troubleshooting

### If RDS doesn't exist yet:
- Wait for Terraform to create RDS first
- Or use a placeholder endpoint temporarily

### If you get "InvalidParameterException":
- Make sure JSON is valid (no trailing commas)
- Escape special characters in password if needed

### If tasks still fail:
- Check CloudWatch Logs for the service
- Verify all 5 keys are present in the secret
- Ensure RDS endpoint is correct and accessible




