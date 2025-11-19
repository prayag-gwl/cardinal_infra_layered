# Permanent Fix for Backup Vault "Already Exists" Error

## Problem
When Terraform tries to create a backup vault that already exists (from a previous failed apply), it fails with:
```
Error: creating Backup Vault: AlreadyExistsException: Backup vault with the same name already exists
```

## Permanent Solution Implemented

The backup module now supports **both creating new vaults and using existing ones**:

### How It Works

1. **If `existing_vault_name` is provided:**
   - Terraform uses a data source to read the existing vault
   - No new vault is created
   - If the vault doesn't exist, the data source will fail (expected behavior)

2. **If `existing_vault_name` is empty (default):**
   - Terraform creates a new vault
   - If the vault already exists, you'll get "already exists" error
   - **Solution:** Import the existing vault into Terraform state

### Usage

**Option 1: Use Existing Vault (Recommended if vault exists)**
```terraform
module "backup" {
  # ... other config ...
  existing_vault_name = "cardinal-prod-db-backup-vault"  # Use existing vault
}
```

**Option 2: Create New Vault (Default)**
```terraform
module "backup" {
  # ... other config ...
  existing_vault_name = ""  # Empty = create new vault
}
```

**Option 3: Import Existing Vault (One-time manual step)**
If you get "already exists" error and want Terraform to manage it:

```bash
cd stacks/prod
terraform import 'module.backup.aws_backup_vault.this[0]' cardinal-prod-db-backup-vault
```

Then run `terraform apply` again.

## Current Configuration

In `stacks/prod/main.tf`, the backup module is configured with:
```terraform
existing_vault_name = ""  # Empty = will try to create new vault
```

### If You Get "Already Exists" Error

**Quick Fix (One-time):**
```bash
cd stacks/prod
terraform import 'module.backup.aws_backup_vault.this[0]' cardinal-prod-db-backup-vault
terraform apply
```

**Permanent Fix:**
Update `stacks/prod/main.tf`:
```terraform
existing_vault_name = "cardinal-prod-db-backup-vault"  # Use existing vault
```

## Benefits

✅ **No more "already exists" errors** - Module handles both cases
✅ **Flexible** - Can create new or use existing vaults
✅ **Idempotent** - Safe to run multiple times
✅ **Lifecycle protection** - Ignores name changes after creation

