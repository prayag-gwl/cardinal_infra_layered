# Backup Configuration Update - Variables and Secrets

## 🔄 Changes Made

The PROD Terraform configuration has been updated to **use existing backup resources** instead of creating new ones:

1. ✅ **Use existing backup vault** (if provided)
2. ✅ **Use existing backup plan** (if provided) - **No new backup plan will be created**
3. ✅ **Use existing KMS key** for backup vault encryption
4. ✅ **Use existing IAM role** for AWS Backup (if provided)

---

## 📋 NEW Variables to Add/Update

### ✅ Required Variables (if using existing backup)

Add these in: **Settings → Secrets and variables → Actions → Variables**

| Variable Name | Value | Description | Required? |
|--------------|-------|-------------|-----------|
| `USW1_EXISTING_BACKUP_PLAN_ID` | `28d45e9a-b621-4d97-8870-0b33b8149651` | ID of existing backup plan | ✅ **YES** - to avoid plan creation |
| `USW1_BACKUP_KMS_KEY_ARN` | `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310` | KMS key ARN for backup vault | ✅ **YES** |
| `USW1_BACKUP_IAM_ROLE_ARN` | `arn:aws:iam::121577249019:role/service-role/AWSBackupDefaultServiceRole` | IAM role ARN for AWS Backup | ✅ **SET** |

**Note**: `USW1_EXISTING_BACKUP_VAULT_NAME` is **NOT needed** - the existing backup plan already has a vault associated with it.

---

## 🔍 How to Get Existing Backup Values

### Get Backup Vault Name:
```bash
# Option 1: AWS Console
# Go to: AWS Backup → Backup vaults → Find your vault name

# Option 2: AWS CLI (if you have permissions)
aws backup list-backup-vaults --region us-west-1 \
  --query "BackupVaultList[?contains(BackupVaultName, 'cardinal') || contains(BackupVaultName, 'prod') || contains(BackupVaultName, 'db')].[BackupVaultName]" \
  --output text
```

### Get Backup Plan ID:
```bash
# Option 1: AWS Console
# Go to: AWS Backup → Backup plans → Click on your plan → Copy the Plan ID

# Option 2: AWS CLI (if you have permissions)
aws backup list-backup-plans --region us-west-1 \
  --query "BackupPlansList[?contains(BackupPlanName, 'cardinal') || contains(BackupPlanName, 'prod') || contains(BackupPlanName, 'db')].[BackupPlanId,BackupPlanName]" \
  --output table
```

### Get Backup IAM Role ARN:
```bash
# Option 1: AWS Console
# Go to: IAM → Roles → Search for "backup" → Copy the Role ARN

# Option 2: AWS CLI
aws iam list-roles --query "Roles[?contains(RoleName, 'backup')].[RoleName,Arn]" --output table
```

---

## 📝 Updated Variable List

### All Variables (Including Backup)

#### Required Variables:
1. `USW1_AWS_REGION` = `us-west-1`
2. `USW1_PROJECT` = `cardinal`
3. `USW1_ENVIRONMENT` = `prod`
4. `USW1_EXISTING_VPC_ID` = `vpc-0d55fd072ff0e07c6`
5. `USW1_EXISTING_PUBLIC_SUBNETS` = `subnet-064f7edf88ed74436,subnet-0369bc2294fb8dc4e`
6. `USW1_EXISTING_PRIVATE_SUBNETS` = `subnet-07bdf2bf355201c1b,subnet-094d13ae0590dd91c`
7. `USW1_EXISTING_RDS_SG_ID` = `sg-00d7fa46f49856145`
8. `USW1_EXISTING_RDS_ENDPOINT` = (get from RDS console)
9. `USW1_EXISTING_RDS_IDENTIFIER` = `cardinal-db`
10. `USW1_DATABASE_SECRET_ARN` = `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/prod-db-creds-5z8Ueg`
11. `USW1_FRONTEND_IMAGE` = (your frontend image)
12. `USW1_BACKEND_IMAGE` = (your backend image)
13. **`USW1_EXISTING_BACKUP_PLAN_ID`** = ⚠️ **NEW - REQUIRED** = `28d45e9a-b621-4d97-8870-0b33b8149651`
14. **`USW1_BACKUP_KMS_KEY_ARN`** = ⚠️ **NEW - REQUIRED** = `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310`

#### Optional Variables:
- `USW1_EXISTING_DB_SUBNETS` = (leave empty)
- `USW1_FRONTEND_CERTIFICATE_ARN` = (your cert ARN)
- `USW1_BACKEND_CERTIFICATE_ARN` = (your cert ARN)
- `USW1_WAF_WEB_ACL_ARN` = (your WAF ARN)
- **`USW1_BACKUP_IAM_ROLE_ARN`** = ✅ **SET** = `arn:aws:iam::121577249019:role/service-role/AWSBackupDefaultServiceRole`
- **`USW1_EXISTING_BACKUP_VAULT_NAME`** = ❌ **NOT NEEDED** (existing backup plan already has vault)

---

## 🔐 Secrets (No Changes)

The secrets remain the same:
- `USW1_TF_BACKEND_BUCKET`
- `USW1_TF_BACKEND_KEY`
- `USW1_TF_BACKEND_REGION`
- `USW1_TF_BACKEND_DDB_TABLE`
- `USW1_TF_BACKEND_KMS_KEY_ID` (optional)
- `USW1_AWS_ROLE_ARN`

---

## ✅ What Changed in Terraform

### Before:
- ❌ Created new backup vault
- ❌ Created new backup plan
- ❌ Created new KMS key (if not provided)
- ❌ Created new IAM role (if not provided)

### After:
- ✅ Uses existing backup vault (if `USW1_EXISTING_BACKUP_VAULT_NAME` provided)
- ✅ Uses existing backup plan (if `USW1_EXISTING_BACKUP_PLAN_ID` provided) - **NO NEW PLAN CREATED**
- ✅ Uses existing KMS key (always, `create_kms_key = false`)
- ✅ Uses existing IAM role (if `USW1_BACKUP_IAM_ROLE_ARN` provided)

---

## 🚨 Important Notes

1. **Backup Plan Creation**: Since `USW1_EXISTING_BACKUP_PLAN_ID` is provided (`28d45e9a-b621-4d97-8870-0b33b8149651`), Terraform will **NOT create a new backup plan**. This prevents the error you encountered.

2. **Backup Vault**: **NOT NEEDED** - The existing backup plan already has a vault associated with it. Terraform will not create a new vault.

3. **KMS Key**: The configuration now **always uses the existing KMS key** (`create_kms_key = false`). The KMS key ARN is set to `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310`.

4. **IAM Role**: If you provide `USW1_BACKUP_IAM_ROLE_ARN`, Terraform will use it. Otherwise, it will create a new role (but this is optional).

---

## 📋 Quick Checklist

Before deploying, ensure:

- [x] `USW1_EXISTING_BACKUP_PLAN_ID` is set = `28d45e9a-b621-4d97-8870-0b33b8149651` ✅
- [x] `USW1_BACKUP_KMS_KEY_ARN` is set = `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310` ✅
- [x] `USW1_BACKUP_IAM_ROLE_ARN` is set = `arn:aws:iam::121577249019:role/service-role/AWSBackupDefaultServiceRole` ✅
- [ ] All other required variables are set (see `GITHUB_VARIABLES_AND_SECRETS.md`)
- [x] `USW1_EXISTING_BACKUP_VAULT_NAME` is **NOT needed** ✅ (existing plan has vault)

---

## 🔍 Finding Your Backup Resources

### In AWS Console:

1. **Backup Vault**:
   - Go to: **AWS Backup** → **Backup vaults**
   - Look for vaults containing: `cardinal`, `prod`, `db`, or `backup`
   - Copy the **Vault name**

2. **Backup Plan**:
   - Go to: **AWS Backup** → **Backup plans**
   - Look for plans containing: `cardinal`, `prod`, `db`, or `backup`
   - Click on the plan → Copy the **Plan ID** (not the name)

3. **IAM Role**:
   - Go to: **IAM** → **Roles**
   - Search for: `backup`
   - Look for roles like: `*-backup-role` or `AWSBackup*`
   - Copy the **Role ARN**

---

## 🚀 Next Steps

1. **Get backup vault name and plan ID** from AWS Console
2. **Add the 3 new variables** to GitHub:
   - `USW1_EXISTING_BACKUP_VAULT_NAME`
   - `USW1_EXISTING_BACKUP_PLAN_ID`
   - `USW1_BACKUP_IAM_ROLE_ARN` (optional)
3. **Verify** `USW1_BACKUP_KMS_KEY_ARN` is set correctly
4. **Run the workflow** - it should now use existing backup resources instead of trying to create new ones

