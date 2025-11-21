# GitHub Variables and Secrets - Complete List

This document lists **ALL** GitHub repository variables and secrets required for PROD Terraform deployment.

**Location**: GitHub Repository → Settings → Secrets and variables → Actions

---

## 📋 GITHUB VARIABLES (Non-Sensitive)

Set these in: **Variables** tab

### ✅ Required Variables

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `USW1_AWS_REGION` | `us-west-1` | AWS region for PROD deployment |
| `USW1_PROJECT` | `cardinal` | Project name |
| `USW1_ENVIRONMENT` | `prod` | Environment name |
| `USW1_EXISTING_VPC_ID` | `vpc-0d55fd072ff0e07c6` | VPC ID of existing cardinal-vpc |
| `USW1_EXISTING_PUBLIC_SUBNETS` | `subnet-064f7edf88ed74436,subnet-0369bc2294fb8dc4e` | **Comma-separated** public subnet IDs (no spaces) |
| `USW1_EXISTING_PRIVATE_SUBNETS` | `subnet-07bdf2bf355201c1b,subnet-094d13ae0590dd91c` | **Comma-separated** private subnet IDs (no spaces) |
| `USW1_EXISTING_RDS_SG_ID` | `sg-00d7fa46f49856145` | Security group ID of existing RDS instance |
| `USW1_EXISTING_RDS_ENDPOINT` | ⚠️ **REQUIRED** - Get from RDS console | RDS endpoint hostname (e.g., `cardinal-db.xxxxx.us-west-1.rds.amazonaws.com`) |
| `USW1_EXISTING_RDS_IDENTIFIER` | `cardinal-db` | RDS instance identifier |
| `USW1_DATABASE_SECRET_ARN` | `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg` | Secrets Manager ARN for PROD DB credentials |
| `USW1_FRONTEND_IMAGE` | `develop-e86163776efc6e31edf1d8cb642a56288418959d` | Container image for frontend service (update with your image) |
| `USW1_BACKEND_IMAGE` | `develop-e86163776efc6e31edf1d8cb642a56288418959d` | Container image for backend service (update with your image) |

### 🔧 Optional Variables

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `USW1_EXISTING_DB_SUBNETS` | (leave empty) | Optional: DB subnet IDs if separate from private (comma-separated) |
| `USW1_FRONTEND_CERTIFICATE_ARN` | (your cert ARN) | ACM certificate ARN for HTTPS listener on ALB |
| `USW1_BACKEND_CERTIFICATE_ARN` | (your cert ARN) | Alternative certificate ARN if frontend is empty |
| `USW1_WAF_WEB_ACL_ARN` | (your WAF ARN) | Optional WAF Web ACL ARN to attach to ALB |
| `USW1_BACKUP_KMS_KEY_ARN` | `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310` | KMS key ARN for backup vault encryption |
| `USW1_EXISTING_BACKUP_PLAN_ID` | `28d45e9a-b621-4d97-8870-0b33b8149651` | ID of existing backup plan (prevents plan creation) |
| `USW1_BACKUP_IAM_ROLE_ARN` | `arn:aws:iam::121577249019:role/service-role/AWSBackupDefaultServiceRole` | IAM role ARN for AWS Backup |

---

## 🔐 GITHUB SECRETS (Sensitive)

Set these in: **Secrets** tab

### ✅ Required Secrets (Terraform Backend)

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `USW1_TF_BACKEND_BUCKET` | (your S3 bucket name) | S3 bucket name for Terraform state storage |
| `USW1_TF_BACKEND_KEY` | (your state key) | S3 key/path for Terraform state file (e.g., `envs/prod/terraform.tfstate`) |
| `USW1_TF_BACKEND_REGION` | `us-west-1` | AWS region where S3 backend bucket is located |
| `USW1_TF_BACKEND_DDB_TABLE` | (your DynamoDB table name) | DynamoDB table name for state locking (e.g., `tf-locks-prod`) |
| `USW1_TF_BACKEND_KMS_KEY_ID` | (optional) | KMS key ID for encrypting state (optional, leave empty if not used) |

### ✅ Required Secrets (AWS Authentication)

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `USW1_AWS_ROLE_ARN` | (your IAM role ARN) | IAM role ARN for GitHub OIDC authentication (e.g., `arn:aws:iam::121577249019:role/github-actions-role`) |

---

## 📝 Quick Copy-Paste Values

### Variables (Copy these exact values)

```
USW1_AWS_REGION=us-west-1
USW1_PROJECT=cardinal
USW1_ENVIRONMENT=prod
USW1_EXISTING_VPC_ID=vpc-0d55fd072ff0e07c6
USW1_EXISTING_PUBLIC_SUBNETS=subnet-064f7edf88ed74436,subnet-0369bc2294fb8dc4e
USW1_EXISTING_PRIVATE_SUBNETS=subnet-07bdf2bf355201c1b,subnet-094d13ae0590dd91c
USW1_EXISTING_RDS_SG_ID=sg-00d7fa46f49856145
USW1_EXISTING_RDS_IDENTIFIER=cardinal-db
USW1_DATABASE_SECRET_ARN=arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg
USW1_BACKUP_KMS_KEY_ARN=arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310
USW1_EXISTING_BACKUP_PLAN_ID=28d45e9a-b621-4d97-8870-0b33b8149651
USW1_BACKUP_IAM_ROLE_ARN=arn:aws:iam::121577249019:role/service-role/AWSBackupDefaultServiceRole
```

### ⚠️ Values You Need to Get/Set:

1. **USW1_EXISTING_RDS_ENDPOINT** - Get from:
   - AWS Console: RDS → Databases → `cardinal-db` → Copy Endpoint
   - Or AWS CLI: `aws rds describe-db-instances --db-instance-identifier cardinal-db --query "DBInstances[0].Endpoint.Address" --output text`

2. **USW1_FRONTEND_IMAGE** - Your frontend container image (update with actual image)
3. **USW1_BACKEND_IMAGE** - Your backend container image (update with actual image)
4. **USW1_FRONTEND_CERTIFICATE_ARN** - Your ACM certificate ARN (if using HTTPS)
5. **USW1_TF_BACKEND_BUCKET** - Your Terraform state S3 bucket name
6. **USW1_TF_BACKEND_KEY** - Your Terraform state file path
7. **USW1_TF_BACKEND_DDB_TABLE** - Your DynamoDB lock table name
8. **USW1_AWS_ROLE_ARN** - Your GitHub OIDC IAM role ARN

---

## 🔍 How to Get Missing Values

### Get RDS Endpoint:
```bash
aws rds describe-db-instances \
  --db-instance-identifier cardinal-db \
  --region us-west-1 \
  --query "DBInstances[0].Endpoint.Address" \
  --output text
```

### Get from Secrets Manager (if you have access):
```bash
aws secretsmanager get-secret-value \
  --secret-id "arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg" \
  --query "SecretString" \
  --output text | jq -r '.host'
```

### Get Terraform Backend Values:
These should already exist from your bootstrap setup. Check:
- S3 bucket for state storage
- DynamoDB table for locking
- KMS key (if used) for encryption

---

## ✅ Checklist

Before deploying, ensure you have:

- [ ] All **Required Variables** set (12 variables)
- [ ] All **Required Secrets** set (6 secrets)
- [ ] `USW1_EXISTING_RDS_ENDPOINT` value retrieved and set
- [ ] Container images (`USW1_FRONTEND_IMAGE`, `USW1_BACKEND_IMAGE`) updated with actual values
- [ ] Terraform backend secrets configured (S3 bucket, DynamoDB table, etc.)
- [ ] AWS OIDC role ARN configured (`USW1_AWS_ROLE_ARN`)
- [ ] Optional variables set if needed (certificates, WAF, etc.)

---

## 📌 Notes

1. **Subnet IDs Format**: Use comma-separated values with **NO SPACES** (e.g., `subnet-abc,subnet-def`)
2. **RDS Endpoint**: This is the hostname, not the full connection string (e.g., `cardinal-db.xxxxx.us-west-1.rds.amazonaws.com`)
3. **Secret ARN**: Use the full ARN including the random suffix (e.g., `...secret:cardinal/prod-db-creds-5z8Ueg`)
4. **Backend Secrets**: These are for Terraform state management and should already exist from bootstrap
5. **OIDC Role**: Must be configured with GitHub OIDC trust policy for the workflow to assume the role

---

## 🚀 After Setting Variables

1. Verify all variables are set in GitHub
2. Run the workflow: **Actions** → **USW1 Terraform Apply** → **Run workflow**
3. Monitor the workflow execution
4. Check Terraform plan output before applying

