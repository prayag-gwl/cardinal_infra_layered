# Terraform Apply Errors - Fix Summary (Second Attempt)

## Errors Found in Apply Logs (logs_50498725906.zip)

### 1. ⚠️ Security Group Already Exists

**Error:**
```
Error: creating Security Group (cardinal-prod-alb-sg): operation error EC2: CreateSecurityGroup, 
https response error StatusCode: 400, RequestID: f3153992-b083-476e-b190-1d6a30a72573, 
api error InvalidGroup.Duplicate: The security group 'cardinal-prod-alb-sg' already exists 
for VPC 'vpc-0d55fd072ff0e07c6'
```

**Root Cause:**
- The security group `cardinal-prod-alb-sg` was created in a previous apply attempt.
- It still exists in AWS, but Terraform state doesn't know about it (likely because the previous apply failed before state was saved).
- Terraform is trying to create it again, causing a duplicate error.

**Fix:**
Import the existing security group into Terraform state:

```bash
cd stacks/prod
terraform import aws_security_group.prod_alb sg-<SECURITY_GROUP_ID>
```

To find the security group ID:
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=cardinal-prod-alb-sg" "Name=vpc-id,Values=vpc-0d55fd072ff0e07c6" \
  --query "SecurityGroups[0].GroupId" \
  --output text \
  --region us-west-1
```

---

### 2. ⚠️ Backup Vault Already Exists

**Error:**
```
Error: creating Backup Vault (cardinal-prod-db-backup-vault): operation error Backup: CreateBackupVault, 
https response error StatusCode: 400, RequestID: 4e4d8c80-6716-4efa-93a6-bf957cc678d2, 
AlreadyExistsException: Backup vault with the same name already exists
```

**Root Cause:**
- The backup vault `cardinal-prod-db-backup-vault` was created in a previous apply attempt.
- It still exists in AWS, but Terraform state doesn't know about it.
- Terraform is trying to create it again.

**Fix Options:**

**Option A: Import Existing Vault (Recommended)**
```bash
cd stacks/prod
terraform import 'module.backup.aws_backup_vault.this[0]' cardinal-prod-db-backup-vault
```

**Option B: Use Existing Vault Name**
- Set GitHub variable `USW1_EXISTING_BACKUP_VAULT_NAME` to `cardinal-prod-db-backup-vault`
- The code will use a data source instead of trying to create it.

**Option C: Delete and Recreate** (Not recommended - may have backups)
```bash
# WARNING: This will delete the vault and any backups!
aws backup delete-backup-vault --backup-vault-name cardinal-prod-db-backup-vault --region us-west-1
```

---

## Resources Successfully Created

From the logs, these resources were created successfully:
- ✅ Random string for ALB logs
- ✅ CloudWatch Log Groups (frontend, backend, exec)
- ✅ IAM Roles (task and task_exec for frontend and backend)
- ✅ ECR Repositories (frontend and backend)
- ✅ ECS Cluster and Capacity Providers
- ✅ ECS Task Definitions (frontend and backend)
- ✅ S3 Bucket for ALB logs
- ✅ SNS Topic for alerts
- ✅ CloudWatch Alarms (RDS CPU, RDS Storage)
- ✅ ALB Target Groups (frontend and backend)

## Resources Failed to Create

- ❌ Security Group: `cardinal-prod-alb-sg` (already exists - needs import)
- ❌ Backup Vault: `cardinal-prod-db-backup-vault` (already exists - needs import or use existing)
- ❌ ALB (depends on security group)
- ❌ ALB Listeners (depend on ALB)
- ❌ ALB Listener Rules (depend on listeners)
- ❌ ECS Security Group: `cardinal-prod-ecs-sg` (likely also exists)
- ❌ ECS Services (depend on security groups and ALB)

---

## Quick Fix Commands

### Step 1: Find Security Group IDs

```bash
# Find ALB security group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=cardinal-prod-alb-sg" "Name=vpc-id,Values=vpc-0d55fd072ff0e07c6" \
  --query "SecurityGroups[0].GroupId" \
  --output text \
  --region us-west-1

# Find ECS security group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=cardinal-prod-ecs-sg" "Name=vpc-id,Values=vpc-0d55fd072ff0e07c6" \
  --query "SecurityGroups[0].GroupId" \
  --output text \
  --region us-west-1
```

### Step 2: Import Resources

```bash
cd stacks/prod

# Import ALB security group (replace <SG_ID> with actual ID)
terraform import aws_security_group.prod_alb <SG_ID>

# Import ECS security group (replace <SG_ID> with actual ID)
terraform import aws_security_group.prod_ecs <SG_ID>

# Import backup vault
terraform import 'module.backup.aws_backup_vault.this[0]' cardinal-prod-db-backup-vault
```

### Step 3: Re-run Apply

```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## Alternative: Use Data Sources Instead

If you prefer not to import, you can modify the code to use data sources for existing resources:

1. **Security Groups**: Use `data "aws_security_group"` to reference existing ones
2. **Backup Vault**: Already supported via `existing_backup_vault_name` variable

However, importing is the recommended approach as it maintains full Terraform management.

---

## Summary

- **2 resources need to be imported**: Security groups and backup vault
- **All other resources created successfully** in this attempt
- **Next apply should succeed** after importing the existing resources

