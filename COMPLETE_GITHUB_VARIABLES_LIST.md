# Complete GitHub Variables and Secrets List for USW1 (us-west-1)

This document provides a comprehensive list of ALL variables and secrets required for the USW1 Terraform deployment on the develop branch.

---

## 🔴 REQUIRED REPOSITORY VARIABLES (vars.USW1_*)

### Basic Configuration
| Variable Name | Required | Description | Example Value |
|--------------|----------|-------------|---------------|
| `USW1_PROJECT` | ✅ Yes | Project name used for resource naming and tagging | `cardinal` |
| `USW1_ENVIRONMENT` | ✅ Yes | Environment name (e.g., prod, dev) | `prod` |
| `USW1_AWS_REGION` | ✅ Yes | AWS region for deployment | `us-west-1` |
| `USW1_VPC_CIDR` | ✅ Yes | CIDR block for the VPC | `10.0.0.0/16` |

### Network Configuration
| Variable Name | Required | Description | Example Value |
|--------------|----------|-------------|---------------|
| `USW1_AZS` | ✅ Yes | Comma-separated availability zones | `us-west-1a,us-west-1c` |
| `USW1_PUBLIC_SUBNET_CIDRS` | ✅ Yes | Comma-separated public subnet CIDRs (must match AZ count) | `10.0.1.0/24,10.0.3.0/24` |
| `USW1_PRIVATE_SUBNET_CIDRS` | ✅ Yes | Comma-separated private subnet CIDRs (must match AZ count) | `10.0.101.0/24,10.0.103.0/24` |
| ~~`USW1_DATA_SUBNET_CIDRS`~~ | ❌ **Not Needed** | **Not required** - Since RDS database already exists, data subnets are not needed. Your existing RDS is already in its own subnet group. | (omit or leave empty) |

### Container Images
| Variable Name | Required | Description | Example Value |
|--------------|----------|-------------|---------------|
| `USW1_FRONTEND_IMAGE` | ✅ Yes | Frontend container image (full ECR URI or just tag) | `public.ecr.aws/.../frontend:tag` or `develop-abc123` |
| `USW1_BACKEND_IMAGE` | ✅ Yes | Backend container image (full ECR URI or just tag) | `public.ecr.aws/.../backend:tag` or `develop-abc123` |

### Database Configuration (Existing Resources)
| Variable Name | Required | Description | Example Value |
|--------------|----------|-------------|---------------|
| `USW1_EXISTING_RDS_IDENTIFIER` | ✅ Yes | **RDS instance identifier** (the AWS RDS instance name, NOT the PostgreSQL database name) | `cardinal-db` |
| `USW1_DATABASE_NAME` | ✅ Yes | **PostgreSQL database name** (will be set as `DB_NAME` environment variable in ECS tasks) | `cardinal-prod-db` |
| `USW1_DATABASE_SECRET_ARN` | ✅ Yes | **Full ARN of your existing Secrets Manager secret** (should contain `host`, `username`, `password`, `port` - but NOT `database`) | `arn:aws:secretsmanager:us-west-1:123456789012:secret:cardinal/prod/db-abc123` |
| ~~`USW1_DB_MASTER_USERNAME`~~ | ❌ **NOT NEEDED** | **Not used** - RDS already exists, credentials are in Secrets Manager | (omit) |
| ~~`USW1_DB_MASTER_PASSWORD`~~ | ❌ **NOT NEEDED** | **Not used** - RDS already exists, credentials are in Secrets Manager | (omit) |
| ~~`USW1_DB_KMS_KEY_ARN`~~ | ❌ **NOT NEEDED** | **Not used** - Not referenced in Terraform code | (omit) |
| ~~`USW1_DB_ENGINE_VERSION`~~ | ❌ **NOT NEEDED** | **Not used** - Not referenced in Terraform code | (omit) |

### Backup Configuration
| Variable Name | Required | Description | Example Value |
|--------------|----------|-------------|---------------|
| `USW1_BACKUP_KMS_KEY_ARN` | ⚠️ Optional | ARN of existing KMS key for backup vault encryption | `arn:aws:kms:us-west-1:123456789012:key/xyz789-ghi012` |

### Security & Certificates
| Variable Name | Required | Description | Example Value |
|--------------|----------|-------------|---------------|
| `USW1_FRONTEND_CERTIFICATE_ARN` | ⚠️ Optional | ACM certificate ARN for frontend ALB HTTPS (leave empty for HTTP-only) | `arn:aws:acm:us-west-1:123456789012:certificate/abc-123` |
| `USW1_BACKEND_CERTIFICATE_ARN` | ⚠️ Optional | ACM certificate ARN for backend ALB HTTPS (leave empty for HTTP-only) | `arn:aws:acm:us-west-1:123456789012:certificate/def-456` |
| `USW1_WAF_WEB_ACL_ARN` | ⚠️ Optional | WAF Web ACL ARN to associate with public ALB | `arn:aws:wafv2:us-west-1:123456789012:global/webacl/...` |

---

## 🔴 REQUIRED REPOSITORY SECRETS (secrets.USW1_*)

### Database Secrets
| Secret Name | Required | Description | Example Value |
|-------------|----------|-------------|---------------|
| ~~`USW1_DB_MASTER_PASSWORD`~~ | ❌ **NOT NEEDED** | **Not used** - RDS already exists, credentials are in Secrets Manager | (omit) |

### Terraform Backend Configuration (Existing Resources)
| Secret Name | Required | Description | Example Value |
|-------------|----------|-------------|---------------|
| `USW1_TF_BACKEND_BUCKET` | ✅ Yes | **S3 bucket name for Terraform state (already exists)** | `cardinal-terraform-state-usw1` |
| `USW1_TF_BACKEND_KEY` | ✅ Yes | State file key/path | `envs/usw1/terraform.tfstate` |
| `USW1_TF_BACKEND_REGION` | ✅ Yes | Region for state backend | `us-west-1` |
| `USW1_TF_BACKEND_DDB_TABLE` | ✅ Yes | **DynamoDB table name for state locking (already exists)** | `terraform-state-locks-usw1` |
| `USW1_TF_BACKEND_KMS_KEY_ID` | ⚠️ Optional | KMS key ID for state encryption (if using encrypted state) | `abc123-def456-ghi789` |

### AWS Authentication
| Secret Name | Required | Description | Example Value |
|-------------|----------|-------------|---------------|
| `USW1_AWS_ROLE_ARN` | ✅ Yes | IAM role ARN for GitHub Actions OIDC authentication | `arn:aws:iam::123456789012:role/github-actions-usw1` |

---

## 📋 Summary by Category

### ✅ Must Have (Required)
**Variables (12):**
- `USW1_PROJECT`
- `USW1_ENVIRONMENT`
- `USW1_AWS_REGION`
- `USW1_VPC_CIDR`
- `USW1_AZS`
- `USW1_PUBLIC_SUBNET_CIDRS`
- `USW1_PRIVATE_SUBNET_CIDRS`
- `USW1_FRONTEND_IMAGE`
- `USW1_BACKEND_IMAGE`
- `USW1_EXISTING_RDS_IDENTIFIER` ⭐ **Your existing RDS instance identifier**
- `USW1_DATABASE_NAME` ⭐ **PostgreSQL database name** (e.g., `cardinal-prod-db`)
- `USW1_DATABASE_SECRET_ARN` ⭐ **Your existing secret ARN**

**Secrets (5):**
- `USW1_TF_BACKEND_BUCKET` ⭐ **Your existing S3 bucket**
- `USW1_TF_BACKEND_KEY`
- `USW1_TF_BACKEND_REGION`
- `USW1_TF_BACKEND_DDB_TABLE` ⭐ **Your existing DynamoDB table**
- `USW1_AWS_ROLE_ARN`

### ⚠️ Optional (Recommended)
**Variables:**
- ~~`USW1_DATA_SUBNET_CIDRS`~~ **Not needed** - RDS already exists
- ~~`USW1_DB_KMS_KEY_ARN`~~ **Not needed** - Not used in code
- ~~`USW1_DB_ENGINE_VERSION`~~ **Not needed** - Not used in code
- `USW1_BACKUP_KMS_KEY_ARN` (⚠️ Currently exported but NOT passed to backup module - would need code update)
- `USW1_FRONTEND_CERTIFICATE_ARN` (for HTTPS)
- `USW1_BACKEND_CERTIFICATE_ARN` (for HTTPS)
- `USW1_WAF_WEB_ACL_ARN` (for WAF protection)

**Secrets:**
- `USW1_TF_BACKEND_KMS_KEY_ID` (if using encrypted state)

---

## 🔍 How to Find Your Existing Resource Values

### 1. RDS Identifier (`USW1_EXISTING_RDS_IDENTIFIER`)
```bash
aws rds describe-db-instances --region us-west-1 \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' \
  --output table
```
**Use the `DBInstanceIdentifier` value (e.g., `cardinal-prod-db`)**

### 2. Secrets Manager ARN (`USW1_DATABASE_SECRET_ARN`)
```bash
aws secretsmanager list-secrets --region us-west-1 \
  --query 'SecretList[?contains(Name, `cardinal`) || contains(Name, `prod`) || contains(Name, `db`)].{Name:Name,ARN:ARN}' \
  --output table
```
**Use the full `ARN` value (e.g., `arn:aws:secretsmanager:us-west-1:123456789012:secret:cardinal/prod/db-abc123`)**

### 3. KMS Key ARN (`USW1_DB_KMS_KEY_ARN` or `USW1_BACKUP_KMS_KEY_ARN`)
```bash
# List all KMS keys
aws kms list-keys --region us-west-1 --output table

# Get ARN for a specific key
aws kms describe-key --key-id <key-id> --region us-west-1 \
  --query 'KeyMetadata.Arn' --output text

# Or find by alias
aws kms list-aliases --region us-west-1 \
  --query 'Aliases[?contains(AliasName, `cardinal`) || contains(AliasName, `db`) || contains(AliasName, `backup`)].{AliasName:AliasName,TargetKeyId:TargetKeyId}' \
  --output table
```

### 4. S3 Bucket Name (`USW1_TF_BACKEND_BUCKET`)
```bash
aws s3 ls | grep terraform
# Or
aws s3api list-buckets --query 'Buckets[?contains(Name, `terraform`) || contains(Name, `state`)].Name' --output table
```

### 5. DynamoDB Table Name (`USW1_TF_BACKEND_DDB_TABLE`)
```bash
aws dynamodb list-tables --region us-west-1 \
  --query 'TableNames[?contains(@, `terraform`) || contains(@, `lock`) || contains(@, `state`)]' \
  --output table
```

### 6. IAM Role ARN (`USW1_AWS_ROLE_ARN`)
```bash
aws iam list-roles --query 'Roles[?contains(RoleName, `github`) || contains(RoleName, `actions`) || contains(RoleName, `usw1`)].{RoleName:RoleName,Arn:Arn}' --output table
```

---

## 📝 Notes

1. **All variable/secret names must be prefixed with `USW1_`** for the us-west-1 region
2. **`USW1_EXISTING_RDS_IDENTIFIER`** is the **RDS instance identifier** (the AWS RDS instance name), NOT the PostgreSQL database name, NOT the ARN
   - ✅ Correct: `cardinal-db` (if your RDS instance in AWS is named `cardinal-db`)
   - ❌ Wrong: `cardinal-prod-db` (this is the PostgreSQL database name, not the instance identifier)
   - ❌ Wrong: `arn:aws:rds:us-west-1:123456789012:db:cardinal-db` (this is the ARN)

3. **`USW1_DATABASE_NAME`** is the **PostgreSQL database name** (will be set as `DB_NAME` environment variable)
   - ✅ Correct: `cardinal-prod-db` (for prod)
   - ✅ Correct: `cardinal-db` (for dev)
   - This is stored as an environment variable in the ECS task definition, NOT in Secrets Manager

4. **`USW1_DATABASE_SECRET_ARN`** must be the **full ARN** of the secret (should contain `host`, `username`, `password`, `port` - but NOT `database`)
   - ✅ Correct: `arn:aws:secretsmanager:us-west-1:123456789012:secret:cardinal/prod/db-abc123`
   - ❌ Wrong: `cardinal/prod/db`
4. **S3 and DynamoDB** for Terraform state backend are **already created** - you're just referencing them
5. **RDS and Secrets Manager** are **already created** - Terraform will reference them, not create them
6. **`USW1_DATA_SUBNET_CIDRS` is NOT needed** - Since your RDS database already exists, data subnets are not required.
7. **`USW1_DB_MASTER_USERNAME` and `USW1_DB_MASTER_PASSWORD` are NOT needed** - These are not used in the Terraform code since RDS already exists. Credentials are retrieved from Secrets Manager.
8. **`USW1_DB_KMS_KEY_ARN` and `USW1_DB_ENGINE_VERSION` are NOT needed** - These are not referenced anywhere in the Terraform code.
9. **Comma-separated values** (AZS, subnet CIDRs) should have **no spaces** or **consistent spacing**
   - ✅ Good: `us-west-1a,us-west-1c`
   - ✅ Good: `us-west-1a, us-west-1c`
   - ❌ Bad: `us-west-1a,  us-west-1c` (inconsistent spacing)

---

## ✅ Quick Setup Checklist

- [ ] Set all required variables (12 variables)
- [ ] Set all required secrets (6 secrets)
- [ ] Set optional variables as needed
- [ ] Verify `USW1_EXISTING_RDS_IDENTIFIER` matches your RDS instance name
- [ ] Verify `USW1_DATABASE_SECRET_ARN` is the full ARN of your secret
- [ ] Verify `USW1_TF_BACKEND_BUCKET` matches your existing S3 bucket
- [ ] Verify `USW1_TF_BACKEND_DDB_TABLE` matches your existing DynamoDB table
- [ ] Test workflow with `USW1 Terraform Plan` first

---

## 🚀 Next Steps

1. Add all variables and secrets to GitHub repository settings
2. Run `USW1 Terraform Plan` workflow to validate configuration
3. Review the plan output
4. Run `USW1 Terraform Apply` workflow to deploy infrastructure

