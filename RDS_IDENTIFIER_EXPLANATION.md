# RDS Identifier vs Database Name - Important Clarification

## Understanding the Difference

You have **one RDS instance** with **multiple PostgreSQL databases** inside it:

### RDS Instance (AWS Resource)
- **Instance Identifier**: `cardinal-db` ← This is what `USW1_EXISTING_RDS_IDENTIFIER` needs
- This is the **AWS RDS instance name** you see in the AWS Console
- This is what Terraform uses to reference the RDS instance

### PostgreSQL Databases (Inside the RDS Instance)
- **Dev Database Name**: `cardinal-db` (the PostgreSQL database name)
- **Prod Database Name**: `cardinal-prod-db` (the PostgreSQL database name)
- These are **PostgreSQL databases** within the same RDS instance
- These are what your application connects to

---

## What to Set in GitHub Variables

### `USW1_EXISTING_RDS_IDENTIFIER`
**Value**: `cardinal-db`

**Why?**
- This is the **RDS instance identifier** (the AWS resource name)
- Terraform uses this to look up your existing RDS instance
- This is what you see in AWS Console → RDS → DB Instances

**How to verify:**
```bash
aws rds describe-db-instances --region us-west-1 \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' \
  --output table
```

You should see `cardinal-db` in the `DBInstanceIdentifier` column.

---

## What Should Be in Your Secrets Manager Secret

Your Secrets Manager secret (referenced by `USW1_DATABASE_SECRET_ARN`) should contain:

```json
{
  "host": "cardinal-db.xxxxx.us-west-1.rds.amazonaws.com",
  "database": "cardinal-prod-db",  ← PostgreSQL database name for prod
  "username": "your_username",
  "password": "your_password",
  "port": "5432"
}
```

**Key Points:**
- `host` = RDS endpoint (from the RDS instance)
- `database` = PostgreSQL database name (`cardinal-prod-db` for prod)
- `username` = Database user
- `password` = Database password
- `port` = Database port (usually 5432 for PostgreSQL)

---

## Summary

| What | Value | Where |
|------|-------|-------|
| **RDS Instance Identifier** | `cardinal-db` | GitHub Variable: `USW1_EXISTING_RDS_IDENTIFIER` |
| **PostgreSQL Database Name (Prod)** | `cardinal-prod-db` | Secrets Manager secret: `database` key |
| **PostgreSQL Database Name (Dev)** | `cardinal-db` | Secrets Manager secret: `database` key (for dev environment) |

---

## For Your USW1 (Prod) Deployment

1. **Set `USW1_EXISTING_RDS_IDENTIFIER`** = `cardinal-db` (the RDS instance name)

2. **Ensure your Secrets Manager secret** (referenced by `USW1_DATABASE_SECRET_ARN`) has:
   - `database` = `cardinal-prod-db` (the PostgreSQL database name for prod)
   - `host` = RDS endpoint
   - `username`, `password`, `port` = Database credentials

3. **The ECS services will read** `DB_NAME` from Secrets Manager, which will be `cardinal-prod-db`

---

## Verification Commands

### Check RDS Instance Identifier:
```bash
aws rds describe-db-instances --region us-west-1 \
  --query 'DBInstances[*].DBInstanceIdentifier' \
  --output text
```
**Expected output**: `cardinal-db`

### Check Secrets Manager Secret Structure:
```bash
aws secretsmanager get-secret-value \
  --secret-id <your-secret-arn> \
  --region us-west-1 \
  --query 'SecretString' \
  --output text | jq .
```

**Should contain**:
- `database`: `cardinal-prod-db` (for prod)
- `host`: RDS endpoint
- `username`, `password`, `port`

