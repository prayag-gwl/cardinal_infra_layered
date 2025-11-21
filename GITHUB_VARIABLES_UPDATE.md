# GitHub Variables Update Guide

This document lists all GitHub repository variables that need to be set/updated for the refactored PROD Terraform configuration.

## ✅ Required Variables (Repository Variables)

Set these in: **Settings → Secrets and variables → Actions → Variables**

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `USW1_AWS_REGION` | `us-west-1` | AWS region for PROD deployment |
| `USW1_PROJECT` | `cardinal` | Project name |
| `USW1_ENVIRONMENT` | `prod` | Environment name |
| `USW1_EXISTING_VPC_ID` | `vpc-0d55fd072ff0e07c6` | VPC ID of existing cardinal-vpc |
| `USW1_EXISTING_PUBLIC_SUBNETS` | `subnet-064f7edf88ed74436,subnet-0369bc2294fb8dc4e` | Comma-separated public subnet IDs |
| `USW1_EXISTING_PRIVATE_SUBNETS` | `subnet-07bdf2bf355201c1b,subnet-094d13ae0590dd91c` | Comma-separated private subnet IDs |
| `USW1_EXISTING_DB_SUBNETS` | (leave empty) | Optional: DB subnet IDs if separate from private |
| `USW1_EXISTING_RDS_SG_ID` | `sg-00d7fa46f49856145` | Security group ID of existing RDS instance |
| `USW1_EXISTING_RDS_ENDPOINT` | ⚠️ **GET MANUALLY** | RDS endpoint hostname (see instructions below) |
| `USW1_EXISTING_RDS_IDENTIFIER` | `cardinal-db` | RDS instance identifier |
| `USW1_DATABASE_SECRET_ARN` | `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg` | Secrets Manager ARN for PROD DB credentials (cardinal/prod-db-creds) |
| `USW1_FRONTEND_IMAGE` | (your frontend image) | Container image for frontend service |
| `USW1_BACKEND_IMAGE` | (your backend image) | Container image for backend service |
| `USW1_BACKUP_KMS_KEY_ARN` | `arn:aws:kms:us-west-1:121577249019:key/05d3a25b-6612-4180-b118-ca414eb23e9c` | KMS key ARN for backup vault |

## 🔧 Optional Variables

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `USW1_FRONTEND_CERTIFICATE_ARN` | (your cert ARN) | ACM certificate ARN for HTTPS listener |
| `USW1_BACKEND_CERTIFICATE_ARN` | (your cert ARN) | Alternative certificate ARN if frontend is empty |
| `USW1_WAF_WEB_ACL_ARN` | (your WAF ARN) | Optional WAF Web ACL ARN |

## ⚠️ How to Get RDS Endpoint

Since the current AWS user doesn't have RDS permissions, you need to get the RDS endpoint manually:

### Option 1: AWS Console
1. Go to **RDS** → **Databases**
2. Click on `cardinal-db`
3. Copy the **Endpoint** value (e.g., `cardinal-db.xxxxx.us-west-1.rds.amazonaws.com`)

### Option 2: AWS CLI (with proper permissions)
```bash
aws rds describe-db-instances \
  --db-instance-identifier cardinal-db \
  --region us-west-1 \
  --query "DBInstances[0].Endpoint.Address" \
  --output text
```

### Option 3: From Secrets Manager
If you have access to read the secret value:
```bash
aws secretsmanager get-secret-value \
  --secret-id "arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg" \
  --query "SecretString" \
  --output text | jq -r '.host'
```

## 📋 Variables to REMOVE (No Longer Needed)

These variables are no longer used and can be removed:
- `USW1_VPC_CIDR`
- `USW1_AZS` (kept for reference but not used)
- `USW1_PUBLIC_SUBNET_CIDRS`
- `USW1_PRIVATE_SUBNET_CIDRS`
- `USW1_DATA_SUBNET_CIDRS`
- `USW1_CREATE_RDS`
- `USW1_DATABASE_NAME`
- `USW1_DB_MASTER_USERNAME`
- `USW1_DB_MASTER_PASSWORD`
- `USW1_DB_ENGINE_VERSION`

## 📝 Summary of Changes

### What Changed:
1. **Removed VPC creation** - PROD now reuses existing `cardinal-vpc`
2. **Removed subnet creation** - PROD uses existing subnets via IDs
3. **Removed RDS creation** - PROD reuses existing `cardinal-db` RDS instance
4. **Single ALB** - One ALB handles both frontend and backend (path-based routing)
5. **New security groups** - PROD-specific SGs that reference existing RDS SG

### What Stayed the Same:
- ECS cluster and service modules
- IAM roles and OIDC setup
- S3 + DynamoDB backend configuration
- Monitoring and backup modules

## 🚀 Next Steps

1. **Get RDS Endpoint** using one of the methods above
2. **Set all required variables** in GitHub repository settings
3. **Update terraform.tfvars** if deploying locally (already updated with most values)
4. **Run terraform plan** to verify configuration
5. **Deploy via GitHub Actions** or `terraform apply`

## 📍 Current Values (from AWS queries)

- **VPC ID**: `vpc-0d55fd072ff0e07c6`
- **Public Subnets**: `subnet-064f7edf88ed74436`, `subnet-0369bc2294fb8dc4e`
- **Private Subnets**: `subnet-07bdf2bf355201c1b`, `subnet-094d13ae0590dd91c`
- **RDS Security Group**: `sg-00d7fa46f49856145`
- **RDS Identifier**: `cardinal-db`
- **Database Secret ARN**: `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg` (PROD secret: `cardinal/prod-db-creds`)

