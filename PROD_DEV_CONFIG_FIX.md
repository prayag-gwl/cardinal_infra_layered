# Production vs Dev Configuration Fix

## Problem Identified

The same backend image works in **dev** but fails in **prod** due to a configuration mismatch:

### Dev Configuration (Working) ✅
- `DB_NAME` comes from **Secrets Manager** (secret: `cardinal/db-creds-JJ2qN4:database::`)
- `DB_NAME` is **NOT** set as an environment variable
- Secrets: `DB_HOST`, `DB_NAME`, `DB_PASSWORD`, `DB_PORT`, `DB_USERNAME` (5 secrets)

### Prod Configuration (Broken) ❌
- `DB_NAME` was set as an **environment variable** (`DB_NAME=cardinal-prod-db`)
- `DB_NAME` was **NOT** in Secrets Manager
- Secrets: `DB_HOST`, `DB_PASSWORD`, `DB_PORT`, `DB_USERNAME` (4 secrets, missing `DB_NAME`)

## Root Cause

The TypeORM initialization expects `DB_NAME` to come from Secrets Manager (like in dev), but in prod it was coming from an environment variable. This mismatch causes the "DataSource with name 'default' has already added" error.

## Fix Applied

Updated `stacks/prod/main.tf` to match dev configuration:

1. **Added `DB_NAME` to secrets list**:
   ```hcl
   db_secret_suffixes = [
     { name = "DB_HOST",     suffix = ":host::" },
     { name = "DB_NAME",     suffix = ":database::" },  # ← Added
     { name = "DB_PASSWORD", suffix = ":password::" },
     { name = "DB_PORT",     suffix = ":port::" },
     { name = "DB_USERNAME", suffix = ":username::" },
   ]
   ```

2. **Removed `DB_NAME` from environment variables**:
   ```hcl
   # No DB_NAME as environment variable - it comes from Secrets Manager (matching dev config)
   db_env_vars = {}
   ```

## Next Steps

1. **Verify Secrets Manager secret contains `database` field**:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id "arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/db-creds-JJ2qN4" \
     --region us-west-1 \
     --query SecretString \
     --output text | jq .
   ```
   
   The secret should contain: `host`, `username`, `password`, `port`, and **`database`**

2. **If `database` field is missing**, update the secret:
   ```bash
   # Get current secret
   CURRENT=$(aws secretsmanager get-secret-value \
     --secret-id "arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/db-creds-JJ2qN4" \
     --region us-west-1 \
     --query SecretString \
     --output text)
   
   # Add database field (if missing)
   echo $CURRENT | jq '. + {database: "cardinal-prod-db"}' | \
     aws secretsmanager put-secret-value \
       --secret-id "arn:aws:secretsmanager:us-west-1:121577249019:secret:cardinal/db-creds-JJ2qN4" \
       --region us-west-1 \
       --secret-string file:///dev/stdin
   ```

3. **Apply Terraform changes**:
   - Run Terraform plan to see the changes
   - Apply the changes to update the task definition
   - Force new ECS deployment

4. **Verify**:
   - Check that the new task definition has `DB_NAME` in secrets (not env vars)
   - Monitor logs for successful database connection
   - Verify TypeORM error is resolved

## Expected Result

After this fix:
- ✅ `DB_NAME` will come from Secrets Manager (matching dev)
- ✅ Task definition will have 5 secrets (matching dev)
- ✅ TypeORM initialization should work correctly
- ✅ Database connection should succeed


