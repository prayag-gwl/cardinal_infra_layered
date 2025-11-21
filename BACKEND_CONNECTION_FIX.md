# Backend Database Connection Fix - Step by Step

## Current Status

The backend service is running but **cannot connect to the RDS database** due to:
- **VPC Mismatch**: RDS is in VPC `vpc-0d55fd072ff0e07c6` (cardinal-vpc)
- **ECS is in**: VPC `vpc-0daf7053cc92abd86` (cardinal-prod-vpc)
- **Security Group**: RDS security group doesn't allow traffic from the new VPC

## Error in Logs

```
Error: Connection terminated due to connection timeout
Unable connect the database. Retrying (9)...
```

## Solution: Update RDS Security Group

### Step 1: Find the RDS Security Group

**Option A: AWS Console**
1. Go to **RDS** → **Databases** → Click on `cardinal-db`
2. Scroll to **Connectivity & security** tab
3. Note the **VPC security groups** (usually one group like `sg-xxxxx`)
4. Click on the security group name to open it

**Option B: AWS CLI** (if you have RDS permissions)
```bash
aws rds describe-db-instances \
  --db-instance-identifier cardinal-db \
  --region us-west-1 \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text
```

### Step 2: Add Inbound Rule to RDS Security Group

1. In the **Security Group** page, click **Edit Inbound Rules**
2. Click **Add Rule**
3. Configure:
   - **Type**: `PostgreSQL` (or Custom TCP)
   - **Port**: `5432`
   - **Source**: `10.10.0.0/16` (the new VPC CIDR where ECS is running)
   - **Description**: `Allow PostgreSQL from new ECS VPC (cardinal-prod-vpc)`
4. Click **Save Rules**

### Step 3: Verify and Test

1. **Wait 30 seconds** for the rule to propagate
2. **Force new deployment**:
   ```bash
   aws ecs update-service \
     --cluster cardinal-prod-cluster \
     --service cardinal-prod-backend-service \
     --force-new-deployment \
     --region us-west-1
   ```
3. **Monitor logs**:
   ```bash
   aws logs tail /ecs/cardinal-prod-backend --region us-west-1 --follow
   ```

### Expected Result

After the fix, you should see:
- ✅ Successful database connections
- ✅ Migrations running successfully
- ✅ Seeding completing
- ✅ Application starting without connection errors

## Alternative: Create RDS in New VPC

If you prefer to have RDS in the same VPC as ECS (recommended for production):

1. Set GitHub variable: `USW1_CREATE_RDS = "true"`
2. Set GitHub variables:
   - `USW1_DB_MASTER_USERNAME` = your username
   - `USW1_DB_ENGINE_VERSION` = "17.7"
3. Set GitHub secret: `USW1_DB_MASTER_PASSWORD` = your password
4. Run Terraform apply to create RDS in the new VPC

This ensures proper connectivity and eliminates cross-VPC issues.

## TypeORM Error (Separate Issue)

The TypeORM error "DataSource with name 'default' has already added" is an **application code issue** in the `OB_backend` repository. This needs to be fixed in the application code itself, not in the infrastructure.

**To fix TypeORM error:**
- Check the NestJS/TypeORM configuration
- Ensure data source is only initialized once
- Review module imports that might cause duplicate initialization


