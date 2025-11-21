# Manual Permissions Checklist for AWS Console

## Summary
Add Secrets Manager permissions to **2 IAM Roles** via AWS Console.

---

## Role 1: `cardinal-prod-usw2-frontend-task-exec`

### Steps:
1. Go to **AWS Console** → **IAM** → **Roles**
2. Search for: `cardinal-prod-usw2-frontend-task-exec`
3. Click on the role name
4. Click **"Add permissions"** → **"Create inline policy"**
5. Click **"JSON"** tab
6. **Delete** the default policy and paste this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
```

7. Click **"Next"**
8. **Policy name:** `cardinal-prod-usw2-frontend-exec-secrets`
9. Click **"Create policy"**

---

## Role 2: `cardinal-prod-usw2-backend-task-exec`

### Steps:
1. Go to **AWS Console** → **IAM** → **Roles**
2. Search for: `cardinal-prod-usw2-backend-task-exec`
3. Click on the role name
4. Click **"Add permissions"** → **"Create inline policy"**
5. Click **"JSON"** tab
6. **Delete** the default policy and paste this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
```

7. Click **"Next"**
8. **Policy name:** `cardinal-prod-usw2-backend-exec-secrets`
9. Click **"Create policy"**

---

## Permissions Breakdown

### What each permission does:

1. **`secretsmanager:GetSecretValue`**
   - **Purpose:** Allows ECS to retrieve the database credentials from Secrets Manager
   - **Resource:** `arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*`
   - **Why `*` at the end?** AWS adds a random suffix to secret ARNs, so `*` matches all versions

2. **`kms:Decrypt`**
   - **Purpose:** Allows ECS to decrypt the secret (it's encrypted with KMS)
   - **Resource:** `*` (all KMS keys)
   - **Why needed?** Secrets Manager secrets are encrypted, so decryption permission is required

---

## Verification Steps

After adding both policies:

1. Go to **IAM** → **Roles** → `cardinal-prod-usw2-frontend-task-exec`
2. Click **"Permissions"** tab
3. Verify you see: `cardinal-prod-usw2-frontend-exec-secrets` (inline policy)
4. Repeat for `cardinal-prod-usw2-backend-task-exec`

---

## After Adding Permissions

**IMPORTANT:** You must force a new deployment for ECS services to pick up the new permissions:

### Via AWS Console:
1. Go to **ECS** → **Clusters** → `cardinal-prod-usw2-cluster`
2. Click **"Services"** tab
3. Select `cardinal-prod-usw2-frontend-service`
4. Click **"Update"** → Check **"Force new deployment"** → **"Update"**
5. Repeat for `cardinal-prod-usw2-backend-service`

### Via AWS CLI:
```bash
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-frontend-service \
  --force-new-deployment \
  --region us-west-2

aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-backend-service \
  --force-new-deployment \
  --region us-west-2
```

---

## Quick Reference

| Item | Value |
|------|-------|
| **Region** | `us-west-2` |
| **Account ID** | `121577249019` |
| **Secret Name** | `cardinal/prod-usw2/db` |
| **Secret ARN Pattern** | `arn:aws:secretsmanager:us-west-2:121577249019:secret:cardinal/prod-usw2/db-*` |
| **Frontend Role** | `cardinal-prod-usw2-frontend-task-exec` |
| **Backend Role** | `cardinal-prod-usw2-backend-task-exec` |
| **Frontend Policy Name** | `cardinal-prod-usw2-frontend-exec-secrets` |
| **Backend Policy Name** | `cardinal-prod-usw2-backend-exec-secrets` |




