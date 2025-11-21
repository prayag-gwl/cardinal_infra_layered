# Terraform Apply Errors - Fix Summary

## Errors Found in Apply Logs

### 1. ✅ FIXED: ECS Task Definition - DB_HOST Conflict

**Error:**
```
ClientException: The secret name must be unique and not shared with any new or existing environment variables set on the container, such as 'DB_HOST'.
```

**Root Cause:**
- `DB_HOST` was being set both as:
  - An environment variable: `DB_HOST = var.existing_rds_endpoint`
  - A secret from Secrets Manager: `{ name = "DB_HOST", suffix = ":host::" }`
- ECS doesn't allow the same name for both an environment variable and a secret.

**Fix:**
- Removed `DB_HOST` from environment variables in both frontend and backend service configurations.
- `DB_HOST` now comes only from Secrets Manager (as intended).

**Files Changed:**
- `stacks/prod/main.tf` - Removed `DB_HOST = var.existing_rds_endpoint` from environment_vars

---

### 2. ⚠️ NEEDS ATTENTION: Backup Vault Already Exists

**Error:**
```
AlreadyExistsException: Backup vault with the same name already exists
```

**Root Cause:**
- The backup vault `cardinal-prod-db-backup-vault` already exists.
- `EXISTING_BACKUP_VAULT_NAME` was empty, so Terraform tried to create a new vault.
- The existing backup plan is already associated with a vault.

**Fix Options:**

**Option A: Import Existing Vault (Recommended)**
```bash
cd stacks/prod
terraform import 'module.backup.aws_backup_vault.this[0]' cardinal-prod-db-backup-vault
```

**Option B: Provide Existing Vault Name**
- Set GitHub variable `USW1_EXISTING_BACKUP_VAULT_NAME` to the actual vault name.
- The code will use a data source instead of trying to create it.

**Option C: Use Different Vault Name**
- Change the vault name in `stacks/prod/main.tf` to avoid conflict.

**Current Status:**
- Code updated to use `var.existing_backup_vault_name` if provided.
- If vault name is provided, it will use data source instead of creating.

---

## Summary of Changes

1. ✅ Removed `DB_HOST` from environment variables (frontend and backend)
2. ✅ Updated backup module to use `existing_backup_vault_name` variable
3. ⚠️ Need to either import existing vault or provide vault name in GitHub variables

---

## Next Steps

1. **Import existing backup vault** OR **set `USW1_EXISTING_BACKUP_VAULT_NAME`** in GitHub variables
2. Re-run Terraform apply
3. Verify all resources are created successfully

---

## Resources Created Successfully

From the logs, these resources were created before errors:
- ✅ ALB: `cardinal-prod-alb`
- ✅ Target Groups: `tg-cardinal-prod-frontend-3000`, `tg-cardinal-prod-backend-3000`
- ✅ ECS Cluster: `cardinal-prod-cluster`
- ✅ Security Groups: `cardinal-prod-alb-sg`, `cardinal-prod-ecs-sg`
- ✅ IAM Roles for ECS tasks
- ✅ CloudWatch Log Groups
- ✅ S3 Bucket for ALB logs
- ✅ ALB Listeners and Rules
- ✅ CloudWatch Alarms

## Resources Failed to Create

- ❌ Backup Vault (already exists - needs import or vault name)
- ❌ ECS Task Definitions (fixed - DB_HOST conflict resolved)
- ❌ ECS Services (depends on task definitions)
