# How to Check if Backup Vault Exists in AWS Console

## Steps to Check Backup Vault

### 1. Navigate to AWS Backup Console

1. **Sign in to AWS Console**
   - Go to https://console.aws.amazon.com
   - Make sure you're in the correct region: **us-west-1**

2. **Open AWS Backup Service**
   - In the search bar at the top, type: `AWS Backup`
   - Click on **AWS Backup** service

### 2. Check Backup Vaults

1. **Go to Backup Vaults**
   - In the left sidebar, click on **Backup vaults**
   - Or directly navigate to: https://console.aws.amazon.com/backup/home?region=us-west-1#/vaults

2. **Look for Your Vault**
   - Search for: `cardinal-prod-db-backup-vault`
   - Or scroll through the list of vaults

### 3. What to Look For

**If the vault EXISTS:**
- You'll see `cardinal-prod-db-backup-vault` in the list
- Status will show as **Available** or **Active**
- You can click on it to see details (ARN, KMS key, creation date, etc.)

**If the vault DOES NOT EXIST:**
- The vault name won't appear in the list
- You'll only see other vaults (if any)

### 4. Alternative: Check via AWS CLI

If you have AWS CLI configured, you can also check:

```bash
# List all backup vaults
aws backup list-backup-vaults --region us-west-1

# Check specific vault
aws backup describe-backup-vault \
  --backup-vault-name cardinal-prod-db-backup-vault \
  --region us-west-1
```

**If vault exists:** You'll see the vault details
**If vault doesn't exist:** You'll get an error: `ResourceNotFoundException`

### 5. What Happens in Terraform

**If vault EXISTS:**
- Terraform data source (`data.aws_backup_vault.existing`) will find it
- Terraform will use the existing vault (no creation)
- No "already exists" error

**If vault DOES NOT EXIST:**
- Terraform data source will fail (expected)
- Terraform will create a new vault
- Uses your existing KMS key: `ECS-Prod-KMS-Key`

## Quick Check Summary

**Vault Name to Look For:**
- `cardinal-prod-db-backup-vault`

**Location in Console:**
- AWS Backup → Backup vaults → Search for `cardinal-prod-db-backup-vault`

**Expected Behavior:**
- ✅ **If exists:** Terraform uses it automatically
- ✅ **If doesn't exist:** Terraform creates it with your existing KMS key

## Troubleshooting

**If you see the vault but Terraform still gives "already exists" error:**
- The vault exists but Terraform state doesn't know about it
- **Solution:** Import it:
  ```bash
  cd stacks/prod
  terraform import 'module.backup.aws_backup_vault.this[0]' cardinal-prod-db-backup-vault
  ```

**If you don't see the vault:**
- It doesn't exist yet
- Terraform will create it automatically on next apply
- No action needed

