# Fix Database Connectivity Issue

## Problem

The backend application cannot connect to the RDS database due to a **VPC mismatch**:

- **RDS Instance** (`cardinal-db`): In **existing VPC** `vpc-0d55fd072ff0e07c6` (cardinal-vpc)
- **ECS Tasks**: In **new VPC** `vpc-0daf7053cc92abd86` (cardinal-prod-vpc)
- **Issue**: Security groups can only reference other security groups within the same VPC

## Root Cause

The RDS security group in the existing VPC doesn't allow traffic from the new VPC where ECS tasks are running. Security groups can't reference security groups from different VPCs directly.

## Solutions

### Solution 1: Update RDS Security Group (Quick Fix - Recommended)

Update the RDS security group in the **existing VPC** to allow PostgreSQL traffic from the new VPC's CIDR block.

**Steps:**

1. **Find the RDS Security Group:**
   ```bash
   # Get the security group ID attached to RDS
   aws rds describe-db-instances \
     --db-instance-identifier cardinal-db \
     --region us-west-1 \
     --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
     --output text
   ```

2. **Add Inbound Rule via AWS Console:**
   - Go to **EC2** → **Security Groups** in AWS Console
   - Find the security group attached to RDS instance `cardinal-db`
   - Click **Edit Inbound Rules**
   - Click **Add Rule**
   - Configure:
     - **Type**: PostgreSQL
     - **Port**: 5432
     - **Source**: `10.10.0.0/16` (the new VPC CIDR from Terraform)
     - **Description**: "Allow PostgreSQL from new ECS VPC (cardinal-prod-vpc)"
   - Click **Save Rules**

3. **Or Add Rule via AWS CLI:**
   ```bash
   # Replace RDS_SG_ID with the actual security group ID from step 1
   RDS_SG_ID="sg-xxxxxxxxx"
   
   aws ec2 authorize-security-group-ingress \
     --group-id $RDS_SG_ID \
     --protocol tcp \
     --port 5432 \
     --cidr 10.10.0.0/16 \
     --region us-west-1 \
     --description "Allow PostgreSQL from new ECS VPC (cardinal-prod-vpc)"
   ```

**After this fix:**
- Wait 30 seconds for the rule to propagate
- Force a new ECS deployment to retry the connection
- The backend should now be able to connect to RDS

### Solution 2: Create RDS in New VPC (Long-term Solution)

Since we've already configured RDS creation in Terraform, you can:

1. Set GitHub variables:
   - `USW1_CREATE_RDS` = `"true"`
   - `USW1_DB_MASTER_USERNAME` = your username
   - `USW1_DB_MASTER_PASSWORD` = your password (secret)

2. Run Terraform apply to create RDS in the same VPC as ECS

3. This ensures proper connectivity and eliminates cross-VPC issues

### Solution 3: VPC Peering (Advanced)

Set up VPC peering between the two VPCs for secure communication. This requires:
- Creating a VPC peering connection
- Updating route tables in both VPCs
- Updating security groups

This is more complex and typically not needed if you can use Solution 2.

## Immediate Action

**Use Solution 1** to fix the connectivity issue right now:

1. Get the RDS security group ID
2. Add an inbound rule allowing PostgreSQL (5432) from `10.10.0.0/16`
3. Wait 30 seconds
4. Force new ECS deployment

## Verification

After applying the fix, check the backend logs:

```bash
aws logs tail /ecs/cardinal-prod-backend --region us-west-1 --follow
```

You should see successful database connections instead of timeout errors.


