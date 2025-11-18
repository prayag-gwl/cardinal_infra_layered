# ACTUAL Required Variables - Since RDS Already Exists

## ✅ ACTUALLY REQUIRED Variables (9 variables)

### Basic Configuration
1. `USW1_PROJECT` - Project name
2. `USW1_ENVIRONMENT` - Environment name  
3. `USW1_AWS_REGION` - AWS region (`us-west-1`)
4. `USW1_VPC_CIDR` - VPC CIDR block

### Network Configuration
5. `USW1_AZS` - Availability zones (comma-separated)
6. `USW1_PUBLIC_SUBNET_CIDRS` - Public subnet CIDRs (comma-separated)
7. `USW1_PRIVATE_SUBNET_CIDRS` - Private subnet CIDRs (comma-separated)

### Container Images
8. `USW1_FRONTEND_IMAGE` - Frontend container image
9. `USW1_BACKEND_IMAGE` - Backend container image

### Existing Resources (Required)
10. `USW1_EXISTING_RDS_IDENTIFIER` - **Your existing RDS database identifier** (name, not ARN)
11. `USW1_DATABASE_SECRET_ARN` - **Full ARN of your existing Secrets Manager secret**

---

## ✅ ACTUALLY REQUIRED Secrets (6 secrets)

1. `USW1_TF_BACKEND_BUCKET` - Your existing S3 bucket name for Terraform state
2. `USW1_TF_BACKEND_KEY` - State file key/path
3. `USW1_TF_BACKEND_REGION` - Region for state backend
4. `USW1_TF_BACKEND_DDB_TABLE` - Your existing DynamoDB table name for state locking
5. `USW1_AWS_ROLE_ARN` - IAM role ARN for GitHub Actions OIDC

---

## ❌ NOT NEEDED (Since RDS Already Exists)

These variables are **exported in workflows but NOT USED** in the Terraform code:

1. ~~`USW1_DB_MASTER_USERNAME`~~ - **NOT USED** - RDS already exists, credentials are in Secrets Manager
2. ~~`USW1_DB_MASTER_PASSWORD`~~ - **NOT USED** - RDS already exists, credentials are in Secrets Manager
3. ~~`USW1_DB_KMS_KEY_ARN`~~ - **NOT USED** - Not referenced anywhere in main.tf
4. ~~`USW1_DB_ENGINE_VERSION`~~ - **NOT USED** - Not referenced anywhere in main.tf
5. ~~`USW1_DATA_SUBNET_CIDRS`~~ - **NOT NEEDED** - RDS already exists in its own subnet group

---

## ⚠️ OPTIONAL Variables

1. `USW1_FRONTEND_CERTIFICATE_ARN` - For HTTPS on frontend ALB (optional)
2. `USW1_BACKEND_CERTIFICATE_ARN` - For HTTPS on backend ALB (optional)
3. `USW1_WAF_WEB_ACL_ARN` - For WAF protection (optional)
4. `USW1_BACKUP_KMS_KEY_ARN` - **NOTE**: Currently exported but NOT passed to backup module. If you want to use existing KMS key for backup, the code needs to be updated to pass it to the backup module.
5. `USW1_TF_BACKEND_KMS_KEY_ID` - For encrypted Terraform state (optional)

---

## 🔍 Code Analysis

### What's Actually Used:
- ✅ `var.existing_rds_identifier` - Used in `data.aws_db_instance.existing`
- ✅ `var.database_secret_arn` - Used in `data.aws_secretsmanager_secret.db_credentials` and ECS services
- ❌ `var.db_master_username` - **NOT USED** anywhere in main.tf
- ❌ `var.db_master_password` - **NOT USED** anywhere in main.tf
- ❌ `var.db_kms_key_arn` - **NOT USED** anywhere in main.tf
- ❌ `var.db_engine_version` - **NOT USED** anywhere (not even defined in variables.tf)

### Backup Module:
- The backup module accepts `kms_key_arn` but it's **NOT passed** from main.tf
- If `kms_key_arn` is empty, the module will create its own KMS key
- So `USW1_BACKUP_KMS_KEY_ARN` is currently **not functional** - would need code update to use it

---

## 📋 Corrected Summary

### Required: 11 variables + 6 secrets = 17 total

**Variables (11):**
1. USW1_PROJECT
2. USW1_ENVIRONMENT
3. USW1_AWS_REGION
4. USW1_VPC_CIDR
5. USW1_AZS
6. USW1_PUBLIC_SUBNET_CIDRS
7. USW1_PRIVATE_SUBNET_CIDRS
8. USW1_FRONTEND_IMAGE
9. USW1_BACKEND_IMAGE
10. USW1_EXISTING_RDS_IDENTIFIER ⭐
11. USW1_DATABASE_SECRET_ARN ⭐

**Secrets (6):**
1. USW1_TF_BACKEND_BUCKET ⭐
2. USW1_TF_BACKEND_KEY
3. USW1_TF_BACKEND_REGION
4. USW1_TF_BACKEND_DDB_TABLE ⭐
5. USW1_AWS_ROLE_ARN

### Not Needed (5 variables):
- ~~USW1_DB_MASTER_USERNAME~~ ❌
- ~~USW1_DB_MASTER_PASSWORD~~ ❌
- ~~USW1_DB_KMS_KEY_ARN~~ ❌
- ~~USW1_DB_ENGINE_VERSION~~ ❌
- ~~USW1_DATA_SUBNET_CIDRS~~ ❌

---

## ⚠️ Issue Found

The workflows export `USW1_DB_MASTER_USERNAME` and `USW1_DB_MASTER_PASSWORD` as required, but they are **NOT USED** in the Terraform code. These should be removed from the required list in workflows, or the workflows need to be updated to make them optional.

