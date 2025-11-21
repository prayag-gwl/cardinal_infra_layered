# KMS Key Deletion Issue - Fix Guide

## Problem

If a KMS key is scheduled for deletion, it remains in "Pending Deletion" state for 7-30 days. During this time:
- The key and its alias **still exist**
- You **cannot create a new key with the same alias**
- Terraform will fail with: `AlreadyExistsException: An alias with the name alias/cardinal-prod-db-backup-vault already exists`

## Solution Options

### Option 1: Cancel KMS Key Deletion (Recommended if within waiting period)

If the key is still in "Pending Deletion" state, you can cancel it:

1. Go to **KMS** → **Customer managed keys**
2. Find the key with alias: `alias/cardinal-prod-db-backup-vault`
3. Click on the key
4. Click **Cancel key deletion** button
5. Confirm the cancellation

**After cancellation:**
- The key will be restored to active state
- Terraform can use the existing key (you'll need to import it) OR
- You can delete it immediately and let Terraform create a new one

---

### Option 2: Use an Existing KMS Key (Recommended)

Instead of creating a new KMS key, use an existing one. The backup module supports this.

**Steps:**

1. **Find an existing KMS key ARN** (or use the one you mentioned: `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310`)

2. **Update `stacks/prod/main.tf`** to pass the existing KMS key:

```terraform
module "backup" {
  source            = "../../modules/backup"
  vault_name        = "${var.project}-${var.environment}-db-backup-vault"
  plan_name         = "${var.project}-${var.environment}-db-backup-plan"
  backup_resources  = [data.aws_db_instance.existing.db_instance_arn]
  tags              = local.common_tags
  sns_topic_arn     = ""
  copy_actions      = var.backup_copy_actions
  kms_key_arn       = var.backup_kms_key_arn  # Add this line
  create_kms_key    = false                     # Add this line to prevent creating new key
}
```

3. **The variable `backup_kms_key_arn` already exists** in your variables (from the GitHub workflow), so this should work immediately.

**Benefits:**
- No waiting period
- Reuses existing key
- No alias conflicts

---

### Option 3: Wait for Deletion to Complete

If you can't cancel and don't want to use an existing key:

1. Wait 7-30 days for the key to be permanently deleted
2. Then run Terraform apply again

**Not recommended** - This delays your deployment significantly.

---

## Recommended Action

**Use Option 2** - Update the backup module to use the existing KMS key ARN that's already configured in your GitHub variables (`USW1_BACKUP_KMS_KEY_ARN`).

This is the fastest and cleanest solution!



