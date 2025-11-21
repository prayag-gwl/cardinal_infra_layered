# Manual Steps to Add Secrets Manager Permissions to ECS Task Execution Roles

## Overview
Add Secrets Manager permissions to the ECS task execution roles so they can retrieve database credentials during container initialization.

## IAM Roles That Need Permissions
1. `cardinal-prod-usw2-frontend-task-exec`
2. `cardinal-prod-usw2-backend-task-exec`

## Secret ARN Pattern
The secret name is: `cardinal/prod-usw2/db`
The ARN pattern is: `arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*`

## Method 1: AWS Console (Recommended)

### Step 1: Open IAM Console
1. Go to AWS Console → IAM → Roles
2. Search for: `cardinal-prod-usw2-frontend-task-exec`
3. Click on the role name

### Step 2: Add Inline Policy to Frontend Role
1. Click on **"Add permissions"** → **"Create inline policy"**
2. Click on **"JSON"** tab
3. Paste the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
```

4. Click **"Next"**
5. Policy name: `cardinal-prod-usw2-frontend-exec-secrets`
6. Click **"Create policy"**

### Step 3: Add Inline Policy to Backend Role
1. Go back to IAM → Roles
2. Search for: `cardinal-prod-usw2-backend-task-exec`
3. Click on the role name
4. Click on **"Add permissions"** → **"Create inline policy"**
5. Click on **"JSON"** tab
6. Paste the same policy JSON as above
7. Policy name: `cardinal-prod-usw2-backend-exec-secrets`
8. Click **"Create policy"**

## Method 2: AWS CLI (Faster)

### Step 1: Create Policy Files
Save the policy JSON to files:

**Frontend policy file** (`frontend-exec-secrets-policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
```

**Backend policy file** (`backend-exec-secrets-policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step 2: Apply Policies via CLI

```bash
# Add policy to frontend execution role
aws iam put-role-policy \
  --role-name cardinal-prod-usw2-frontend-task-exec \
  --policy-name cardinal-prod-usw2-frontend-exec-secrets \
  --policy-document file://frontend-exec-secrets-policy.json \
  --region us-west-2

# Add policy to backend execution role
aws iam put-role-policy \
  --role-name cardinal-prod-usw2-backend-task-exec \
  --policy-name cardinal-prod-usw2-backend-exec-secrets \
  --policy-document file://backend-exec-secrets-policy.json \
  --region us-west-2
```

## Step 3: Verify Permissions

### Via AWS Console:
1. Go to IAM → Roles → `cardinal-prod-usw2-frontend-task-exec`
2. Check the **"Permissions"** tab
3. You should see the inline policy `cardinal-prod-usw2-frontend-exec-secrets`
4. Repeat for backend role

### Via AWS CLI:
```bash
# Check frontend role
aws iam get-role-policy \
  --role-name cardinal-prod-usw2-frontend-task-exec \
  --policy-name cardinal-prod-usw2-frontend-exec-secrets \
  --region us-west-2

# Check backend role
aws iam get-role-policy \
  --role-name cardinal-prod-usw2-backend-task-exec \
  --policy-name cardinal-prod-usw2-backend-exec-secrets \
  --region us-west-2
```

## Step 4: Force New ECS Deployment

After adding permissions, force a new deployment so ECS tasks pick up the new IAM permissions:

### Via AWS Console:
1. Go to ECS → Clusters → `cardinal-prod-usw2-cluster`
2. Click on **Services** tab
3. Select `cardinal-prod-usw2-frontend-service`
4. Click **"Update"** → **"Force new deployment"** → **"Update"**
5. Repeat for `cardinal-prod-usw2-backend-service`

### Via AWS CLI:
```bash
# Force new deployment for frontend service
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-frontend-service \
  --force-new-deployment \
  --region us-west-2

# Force new deployment for backend service
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-backend-service \
  --force-new-deployment \
  --region us-west-2
```

## Step 5: Verify Tasks Are Running

1. Go to ECS → Clusters → `cardinal-prod-usw2-cluster` → Services
2. Click on `cardinal-prod-usw2-frontend-service`
3. Go to **"Tasks"** tab
4. Check that tasks are in **"Running"** state (not "Stopped" or "Failed")
5. Click on a task ID to see details
6. Check **"Logs"** tab for any errors
7. Repeat for backend service

## Troubleshooting

### If tasks still fail:
1. Check CloudWatch Logs for the service
2. Verify the secret ARN is correct (check in Secrets Manager console)
3. Verify KMS key permissions (the execution role needs `kms:Decrypt`)
4. Check task execution role ARN matches the role you updated

### To find the exact secret ARN:
```bash
aws secretsmanager describe-secret \
  --secret-id cardinal/prod-usw2/db \
  --region us-west-2 \
  --query 'ARN' \
  --output text
```

## Notes
- The `*` in the secret ARN pattern (`cardinal/prod-usw2/db-*`) allows access to all versions of the secret
- The `kms:Decrypt` permission with `Resource: "*"` is needed because the secret is encrypted with KMS
- These permissions are only needed on the **execution role**, not the task role
- After adding permissions, you MUST force a new deployment for the changes to take effect




