# Latest Terraform Apply Errors - Fix Guide

## Errors Found in Latest Apply (logs_50241593463.zip)

### 1. ✅ FIXED: S3 Bucket Policy - Wrong Service Principal
**Error:**
```
Error: modifying ELBv2 Load Balancer: Access Denied for bucket: cardinal-prod-alb-logs-1a6pqw
```

**Root Cause:** The S3 bucket policy was using the wrong service principal `delivery.logs.amazonaws.com` instead of `logdelivery.elasticloadbalancing.amazonaws.com` for ALB access logs.

**Fix Applied:** 
- Updated service principal to `logdelivery.elasticloadbalancing.amazonaws.com`
- Added account root principal for additional permissions
- Increased `time_sleep` duration from 10s to 30s for better policy propagation

---

### 2. ⚠️ REQUIRES MANUAL ACTION: Backup Vault Already Exists
**Error:**
```
Error: creating Backup Vault (cardinal-prod-db-backup-vault): AlreadyExistsException
```

**Root Cause:** The backup vault `cardinal-prod-db-backup-vault` already exists in your AWS account (likely from a previous failed apply that wasn't fully cleaned up).

**Solution Options:**

**Option A: Delete the Backup Vault (Recommended)**
1. Go to **AWS Backup** → **Backup vaults**
2. Find: `cardinal-prod-db-backup-vault`
3. **First delete all backups** (if any):
   - Click on vault → **Recovery points** → Delete all recovery points
4. **Then delete the vault:**
   - Click → **Delete vault** → Confirm

**Option B: Import Existing Backup Vault**
If you want to keep the existing vault and manage it with Terraform:

```bash
cd stacks/prod
terraform import 'module.backup.aws_backup_vault.this' cardinal-prod-db-backup-vault
```

**Note:** After importing, you may also need to import the backup plan and selection if they exist.

---

### 3. ⚠️ CASCADE ERROR: Target Groups Without Load Balancer
**Error:**
```
Error: creating ECS Service: The target group does not have an associated load balancer
```

**Root Cause:** This is a **cascade error** caused by the ALB creation failure (due to S3 bucket permission issue). When ALBs fail to create, the target groups are created but not associated with a load balancer, causing ECS service creation to fail.

**Fix:** This will be automatically resolved once:
1. The S3 bucket policy is fixed (✅ Done)
2. The backup vault issue is resolved
3. You re-run the Terraform apply

---

### 4. ⚠️ CASCADE ERROR: Missing Resource Identity
**Error:**
```
Error: Missing Resource Identity After Create
```

**Root Cause:** This is a side effect of the ALB creation failure. When ALB fails to configure access logs, Terraform loses track of the resource identity.

**Fix:** This will be automatically resolved once the S3 bucket policy issue is fixed.

---

## Summary of Actions Required

1. ✅ **Fixed in code:** S3 bucket policy service principal and propagation time
2. 🔧 **Manual action needed:** Delete or import the existing backup vault
3. ✅ **Will auto-resolve:** Target group and resource identity errors (cascade from ALB failure)

---

## After Fixes, Re-run Apply

Once you've resolved the backup vault issue:

1. Delete the backup vault (or import it if you want to keep it)
2. Re-run the `USW1 Terraform Apply` workflow
3. The apply should succeed with the corrected S3 bucket policy

---

## Updated S3 Bucket Policy

The policy now includes:
- Account root principal for `s3:PutObject`
- Correct ALB service principal: `logdelivery.elasticloadbalancing.amazonaws.com`
- Proper conditions for bucket ACL
- Increased propagation time (30 seconds)



