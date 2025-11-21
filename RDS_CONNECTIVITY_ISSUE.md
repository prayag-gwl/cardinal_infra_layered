# RDS Connectivity Issue - Cross-VPC Problem

## Problem Identified

The backend application is failing with two errors:

1. **TypeORM Error**: "DataSource with name 'default' has already added" - Application code issue
2. **Database Connection Timeout**: "Connection terminated due to connection timeout" - **Infrastructure issue**

## Root Cause

**VPC Mismatch:**
- **RDS Instance** (`cardinal-db`): In **existing VPC** `vpc-0d55fd072ff0e07c6`
- **ECS Tasks**: In **new VPC** `vpc-0daf7053cc92abd86` (created by Terraform)
- **Security Groups**: Can't reference each other across different VPCs

## Solutions

### Option 1: Allow RDS Security Group to Accept Traffic from New VPC CIDR (Quick Fix)

Update the RDS security group in the **existing VPC** to allow PostgreSQL (port 5432) from the new VPC's CIDR block.

**Steps:**
1. Go to **EC2** → **Security Groups** in AWS Console
2. Find the security group attached to RDS instance `cardinal-db`
3. Edit **Inbound Rules**
4. Add rule:
   - **Type**: PostgreSQL
   - **Port**: 5432
   - **Source**: `10.10.0.0/16` (the new VPC CIDR from Terraform)
   - **Description**: "Allow from new ECS VPC"

**AWS CLI Command:**
```bash
# First, get the RDS security group ID
RDS_SG_ID=$(aws rds describe-db-instances \
  --db-instance-identifier cardinal-db \
  --region us-west-1 \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text)

# Add rule to allow traffic from new VPC
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --cidr 10.10.0.0/16 \
  --region us-west-1 \
  --description "Allow PostgreSQL from new ECS VPC (cardinal-prod-vpc)"
```

### Option 2: VPC Peering (Recommended for Production)

Set up VPC peering between the two VPCs for secure communication.

**Steps:**
1. Create VPC Peering Connection
2. Update Route Tables in both VPCs
3. Update Security Groups to reference peered VPC

**Terraform code would be needed for this.**

### Option 3: Move RDS to New VPC (Not Recommended)

This would require:
- Creating new RDS instance in new VPC
- Migrating data
- Downtime

## Application Code Issue

The TypeORM error "DataSource with name 'default' has already added" needs to be fixed in the application code. This typically happens when:
- Data source is initialized multiple times
- Module imports cause duplicate initialization
- Hot reload in development causes issues

**Fix**: Check the NestJS/TypeORM configuration in `OB_backend` to ensure data source is only initialized once.

## Immediate Action Required

**Update RDS Security Group** to allow traffic from the new VPC:

1. Go to AWS Console → EC2 → Security Groups
2. Find security group for `cardinal-db` RDS instance
3. Add inbound rule: PostgreSQL (5432) from `10.10.0.0/16`

After this, the backend should be able to connect to RDS, and you can address the TypeORM issue separately.


