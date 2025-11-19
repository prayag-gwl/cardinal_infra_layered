# IAM Roles and Permissions Verification

This document verifies that all IAM roles have the necessary permissions for successful deployment.

## ✅ ECS Task Execution Roles

### Frontend Service: `cardinal-prod-frontend-task-exec`
**Purpose**: Used by ECS to pull images, retrieve secrets, and write logs

**Permissions**:
1. ✅ **AmazonECSTaskExecutionRolePolicy** (Managed Policy)
   - Pull images from ECR
   - Write logs to CloudWatch
   - Basic ECS operations

2. ✅ **Inline Policy: `cardinal-prod-frontend-exec-secrets`**
   - `secretsmanager:GetSecretValue` on `arn:aws:secretsmanager:*:secret:cardinal/db-creds-*`
   - `kms:Decrypt` (for encrypted secrets)

3. ✅ **Inline Policy: `cardinal-prod-frontend-exec-ecs-exec`** (if ECS Exec enabled)
   - `ssmmessages:CreateControlChannel`
   - `ssmmessages:CreateDataChannel`
   - `ssmmessages:OpenControlChannel`
   - `ssmmessages:OpenDataChannel`

### Backend Service: `cardinal-prod-backend-task-exec`
**Same permissions as frontend execution role**

---

## ✅ ECS Task Roles

### Frontend Service: `cardinal-prod-frontend-task-role`
**Purpose**: Used by the running container to access AWS services

**Permissions**:
1. ✅ **Inline Policy: `cardinal-prod-frontend-task-secrets`**
   - `secretsmanager:GetSecretValue` on `arn:aws:secretsmanager:*:secret:cardinal/db-creds-*`
   - `kms:Decrypt` (for encrypted secrets)

### Backend Service: `cardinal-prod-backend-task-role`
**Same permissions as frontend task role**

---

## ✅ AWS Backup Role

### Role: `cardinal-prod-db-backup-vault-backup-role`
**Purpose**: Used by AWS Backup service to perform backup and restore operations

**Permissions**:
1. ✅ **AWSBackupServiceRolePolicyForBackup** (Managed Policy)
   - Create backups
   - Manage backup jobs
   - Access backup vaults

2. ✅ **AWSBackupServiceRolePolicyForRestores** (Managed Policy)
   - Perform restore operations
   - Access backup data

**Trust Policy**:
- Service: `backup.amazonaws.com` can assume this role

---

## ✅ CloudWatch Logs Permissions

**Execution Roles** have CloudWatch Logs permissions via `AmazonECSTaskExecutionRolePolicy`:
- `logs:CreateLogStream`
- `logs:PutLogEvents`
- `logs:CreateLogGroup` (if needed)

**Log Groups**:
- `/ecs/cardinal-prod-frontend`
- `/ecs/cardinal-prod-backend`
- `/aws/ecs/cardinal-prod-exec` (for ECS Exec)

---

## ✅ KMS Permissions

**Execution Roles** have:
- `kms:Decrypt` on all keys (for Secrets Manager decryption)

**Backup Vault** uses:
- Existing KMS Key: `arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310`
- Backup role has permissions via managed policies to use KMS keys for backup encryption

---

## ✅ Secrets Manager Permissions

**Execution Roles** can:
- `secretsmanager:GetSecretValue` on `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/db-creds-*`

**Task Roles** can:
- `secretsmanager:GetSecretValue` on `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/db-creds-*`

**Secret ARN Pattern**: `${var.database_secret_arn}*`
- Example: `arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/db-creds-JJ2qN4*`

---

## ✅ ECS Exec Permissions

**Execution Roles** have SSM permissions for ECS Exec:
- `ssmmessages:CreateControlChannel`
- `ssmmessages:CreateDataChannel`
- `ssmmessages:OpenControlChannel`
- `ssmmessages:OpenDataChannel`

**Note**: ECS Exec is enabled by default (`enable_execute_command = true`)

---

## ✅ ECR Permissions

**Execution Roles** have ECR permissions via `AmazonECSTaskExecutionRolePolicy`:
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`

---

## ✅ S3 Permissions (ALB Access Logs)

**ALB Service** has permissions via S3 bucket policy:
- Service: `logdelivery.elasticloadbalancing.amazonaws.com`
- Actions: `s3:PutObject`, `s3:GetBucketAcl`
- Resource: `cardinal-prod-alb-logs-*`

**Note**: No IAM roles needed - ALB uses service-linked permissions

---

## ✅ Auto Scaling Permissions

**ECS Service** uses Application Auto Scaling:
- No additional IAM roles needed
- Uses service-linked role: `AWSServiceRoleForApplicationAutoScaling_ECSService`

---

## ✅ CloudWatch Alarms Permissions

**CloudWatch Alarms** use:
- No IAM roles needed
- Alarms are created by Terraform with appropriate permissions

---

## ✅ SNS Permissions

**SNS Topic**: `cardinal-prod-alerts`
- No IAM roles needed for topic creation
- Email subscriptions don't require IAM permissions

---

## 🔍 Verification Checklist

Before deployment, verify:

- [x] Execution roles have Secrets Manager permissions
- [x] Execution roles have KMS decrypt permissions
- [x] Execution roles have ECS Exec SSM permissions
- [x] Task roles have Secrets Manager permissions (if needed by application)
- [x] Backup role has AWS Backup managed policies
- [x] All roles have correct trust policies
- [x] Secret ARN pattern matches actual secret ARN
- [x] KMS key ARN is correct for backup vault
- [x] Log groups are created before services
- [x] ECR repositories exist or will be created

---

## 🚨 Common Issues and Fixes

### Issue: "Unable to pull secrets from Secrets Manager"
**Fix**: ✅ Execution role has `secretsmanager:GetSecretValue` permission

### Issue: "Access denied for KMS key"
**Fix**: ✅ Execution role has `kms:Decrypt` permission

### Issue: "ECS Exec not working"
**Fix**: ✅ Execution role has SSM permissions for ECS Exec

### Issue: "Cannot pull image from ECR"
**Fix**: ✅ Execution role has `AmazonECSTaskExecutionRolePolicy` attached

### Issue: "Cannot write logs to CloudWatch"
**Fix**: ✅ Execution role has CloudWatch Logs permissions via managed policy

### Issue: "Backup job failed"
**Fix**: ✅ Backup role has AWS Backup managed policies attached

---

## 📝 Summary

All IAM roles are properly configured with:
- ✅ Correct trust policies
- ✅ Necessary managed policies
- ✅ Required inline policies for Secrets Manager
- ✅ KMS decrypt permissions
- ✅ ECS Exec permissions
- ✅ CloudWatch Logs permissions (via managed policy)
- ✅ ECR permissions (via managed policy)

**Status**: ✅ **READY FOR DEPLOYMENT**

All roles and permissions are correctly configured to avoid deployment failures.

