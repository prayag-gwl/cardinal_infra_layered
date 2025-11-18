# ✅ FINAL Required Variables & Secrets for USW1

## Summary: Since RDS Already Exists

**Total Required: 12 Variables + 5 Secrets = 17 items**

---

## ✅ REQUIRED REPOSITORY VARIABLES (12)

### 1. Basic Configuration (4)
- `USW1_PROJECT` - Project name (e.g., `cardinal`)
- `USW1_ENVIRONMENT` - Environment name (e.g., `prod`)
- `USW1_AWS_REGION` - AWS region (e.g., `us-west-1`)
- `USW1_VPC_CIDR` - VPC CIDR block (e.g., `10.0.0.0/16`)

### 2. Network Configuration (3)
- `USW1_AZS` - Availability zones, comma-separated (e.g., `us-west-1a,us-west-1c`)
- `USW1_PUBLIC_SUBNET_CIDRS` - Public subnet CIDRs, comma-separated (e.g., `10.0.1.0/24,10.0.3.0/24`)
- `USW1_PRIVATE_SUBNET_CIDRS` - Private subnet CIDRs, comma-separated (e.g., `10.0.101.0/24,10.0.103.0/24`)

### 3. Container Images (2)
- `USW1_FRONTEND_IMAGE` - Frontend container image (full ECR URI or just tag)
- `USW1_BACKEND_IMAGE` - Backend container image (full ECR URI or just tag)

### 4. Existing Resources (3) ⭐
- `USW1_EXISTING_RDS_IDENTIFIER` - **Your existing RDS instance identifier** (the AWS RDS instance name, NOT the database name)
  - ⚠️ **Important**: This is the RDS **instance identifier**, not the PostgreSQL database name
  - If your RDS instance is named `cardinal-db` in AWS, use: `cardinal-db`
  - Example: `cardinal-db` (the RDS instance name)
  - Find it: `aws rds describe-db-instances --region us-west-1 --query 'DBInstances[*].DBInstanceIdentifier'`
  
- `USW1_DATABASE_NAME` - **PostgreSQL database name** to connect to (will be set as DB_NAME environment variable)
  - ⚠️ **Important**: This is the **PostgreSQL database name** within the RDS instance, NOT the instance identifier
  - For prod: `cardinal-prod-db`
  - For dev: `cardinal-db`
  - This will be set as `DB_NAME` environment variable in ECS task definitions
  
- `USW1_DATABASE_SECRET_ARN` - **Full ARN of your existing Secrets Manager secret**
  - ⚠️ **Important**: The secret should contain `host`, `username`, `password`, `port` (but NOT `database` - that comes from env var)
  - Example: `arn:aws:secretsmanager:us-west-1:123456789012:secret:cardinal/prod/db-abc123`
  - Find it: `aws secretsmanager list-secrets --region us-west-1`

---

## ✅ REQUIRED REPOSITORY SECRETS (5)

### 1. Terraform Backend (4) - Your Existing Resources ⭐
- `USW1_TF_BACKEND_BUCKET` - **Your existing S3 bucket name** for Terraform state
  - Example: `cardinal-terraform-state-usw1`
  - Find it: `aws s3 ls | grep terraform`
  
- `USW1_TF_BACKEND_KEY` - State file key/path
  - Example: `envs/usw1/terraform.tfstate`
  
- `USW1_TF_BACKEND_REGION` - Region for state backend
  - Example: `us-west-1`
  
- `USW1_TF_BACKEND_DDB_TABLE` - **Your existing DynamoDB table name** for state locking
  - Example: `terraform-state-locks-usw1`
  - Find it: `aws dynamodb list-tables --region us-west-1`

### 2. AWS Authentication (1)
- `USW1_AWS_ROLE_ARN` - IAM role ARN for GitHub Actions OIDC
  - Example: `arn:aws:iam::123456789012:role/github-actions-usw1`
  - Find it: `aws iam list-roles --query 'Roles[?contains(RoleName, `github`)]'`

---

## ❌ NOT NEEDED (Since RDS Already Exists)

These are **NOT required** and should **NOT be set**:

1. ~~`USW1_DB_MASTER_USERNAME`~~ - Not used in code
2. ~~`USW1_DB_MASTER_PASSWORD`~~ - Not used in code
3. ~~`USW1_DB_KMS_KEY_ARN`~~ - Not used in code
4. ~~`USW1_DB_ENGINE_VERSION`~~ - Not used in code
5. ~~`USW1_DATA_SUBNET_CIDRS`~~ - Not needed (RDS already exists)

---

## ⚠️ OPTIONAL Variables (If Needed)

- `USW1_FRONTEND_CERTIFICATE_ARN` - For HTTPS on frontend ALB
- `USW1_BACKEND_CERTIFICATE_ARN` - For HTTPS on backend ALB
- `USW1_WAF_WEB_ACL_ARN` - For WAF protection
- `USW1_BACKUP_KMS_KEY_ARN` - ⚠️ Currently exported but NOT passed to backup module (would need code update)
- `USW1_TF_BACKEND_KMS_KEY_ID` - For encrypted Terraform state (optional secret)

---

## 📋 Quick Checklist

### Variables to Add (11):
- [ ] USW1_PROJECT
- [ ] USW1_ENVIRONMENT
- [ ] USW1_AWS_REGION
- [ ] USW1_VPC_CIDR
- [ ] USW1_AZS
- [ ] USW1_PUBLIC_SUBNET_CIDRS
- [ ] USW1_PRIVATE_SUBNET_CIDRS
- [ ] USW1_FRONTEND_IMAGE
- [ ] USW1_BACKEND_IMAGE
- [ ] USW1_EXISTING_RDS_IDENTIFIER ⭐
- [ ] USW1_DATABASE_NAME ⭐ (e.g., `cardinal-prod-db`)
- [ ] USW1_DATABASE_SECRET_ARN ⭐

### Secrets to Add (5):
- [ ] USW1_TF_BACKEND_BUCKET ⭐
- [ ] USW1_TF_BACKEND_KEY
- [ ] USW1_TF_BACKEND_REGION
- [ ] USW1_TF_BACKEND_DDB_TABLE ⭐
- [ ] USW1_AWS_ROLE_ARN

---

## 🔍 Key Points

1. **`USW1_EXISTING_RDS_IDENTIFIER`** = RDS **instance identifier** (the AWS RDS instance name), NOT the PostgreSQL database name, NOT ARN
   - ✅ Correct: `cardinal-db` (if your RDS instance is named `cardinal-db` in AWS)
   - ❌ Wrong: `cardinal-prod-db` (this is the database name, not the instance identifier)
   - ❌ Wrong: `arn:aws:rds:us-west-1:...` (this is the ARN, not the identifier)

2. **`USW1_DATABASE_NAME`** = **PostgreSQL database name** (will be set as `DB_NAME` environment variable)
   - ✅ Correct: `cardinal-prod-db` (for prod environment)
   - ✅ Correct: `cardinal-db` (for dev environment)
   - This is stored as an environment variable, NOT in Secrets Manager

3. **`USW1_DATABASE_SECRET_ARN`** = **Full ARN** of the secret (should contain host, username, password, port - but NOT database name)
   - ✅ Correct: `arn:aws:secretsmanager:us-west-1:123456789012:secret:cardinal/prod/db-abc123`
   - ❌ Wrong: `cardinal/prod/db`

3. **S3 and DynamoDB** are **already created** - just provide their names

4. **RDS and Secrets Manager** are **already created** - Terraform will reference them, not create them

5. **Do NOT set** `USW1_DB_MASTER_USERNAME` or `USW1_DB_MASTER_PASSWORD` - they're not used

