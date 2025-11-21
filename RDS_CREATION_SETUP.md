# RDS Creation Setup Guide

## Overview

The Terraform configuration now supports creating a new RDS database instance (same as deployment branch) or using an existing one. This is controlled by the `create_rds` variable.

## Configuration

### To Create New RDS Database

Set the following GitHub variables and secrets:

**Required Variables:**
- `USW1_CREATE_RDS`: Set to `"true"` to create a new RDS instance
- `USW1_DB_MASTER_USERNAME`: Master username for the RDS database
- `USW1_DB_ENGINE_VERSION`: PostgreSQL engine version (default: `"17.7"`)

**Required Secrets:**
- `USW1_DB_MASTER_PASSWORD`: Master password for the RDS database

**Optional Variables:**
- `USW1_DB_KMS_KEY_ARN`: Existing KMS key ARN for RDS encryption (if not provided, a new key will be created)

### To Use Existing RDS Database

Set the following GitHub variables:

**Required Variables:**
- `USW1_CREATE_RDS`: Set to `"false"` or leave unset (defaults to `false`)
- `USW1_DATABASE_SECRET_ARN`: ARN of existing Secrets Manager secret containing database credentials
- `USW1_DATABASE_NAME`: PostgreSQL database name (e.g., `cardinal-prod-db`)
- `USW1_EXISTING_RDS_IDENTIFIER`: Identifier of the existing RDS instance

## RDS Configuration Details

When `create_rds = true`, the following configuration is used (matching deployment branch):

- **Identifier**: `cardinal-prod-db`
- **Database Name**: `cardinal_prod` (computed from project and environment)
- **Engine**: PostgreSQL
- **Engine Version**: From `USW1_DB_ENGINE_VERSION` (default: `17.7`)
- **Instance Class**: `db.m6g.large` (default from module)
- **Storage**: 
  - Initial: 50 GB
  - Max (autoscaling): 100 GB
- **Multi-AZ**: Enabled
- **Backup Retention**: 14 days
- **Encryption**: Enabled (uses existing KMS key if provided, otherwise creates new one)
- **Performance Insights**: Enabled
- **IAM Database Authentication**: Enabled
- **Deletion Protection**: Enabled
- **Subnets**: Uses data subnets if available, otherwise private subnets
- **Security Group**: Uses the RDS security group from the networking module (allows access from ECS security group)

## Secrets Manager

When creating a new RDS instance, a Secrets Manager secret is automatically created at:
- **Name**: `cardinal/prod/db`
- **Contents**: JSON with `username`, `password`, `host`, `port`, and `database`

This secret is automatically used by the ECS services for database credentials.

## Database Name Environment Variable

The database name is set as the `DB_NAME` environment variable in both frontend and backend ECS services:
- If `create_rds = true`: Uses computed name `cardinal_prod`
- If `create_rds = false`: Uses the value from `USW1_DATABASE_NAME`

## Migration Steps

1. **Set GitHub Variables:**
   ```
   USW1_CREATE_RDS = "true"
   USW1_DB_MASTER_USERNAME = "your_username"
   USW1_DB_ENGINE_VERSION = "17.7"  # Optional, defaults to 17.7
   ```

2. **Set GitHub Secret:**
   ```
   USW1_DB_MASTER_PASSWORD = "your_secure_password"
   ```

3. **Optional - Use Existing KMS Key:**
   ```
   USW1_DB_KMS_KEY_ARN = "arn:aws:kms:us-west-1:121577249019:key/6095c589-7d7e-4581-b4f7-cc2009762310"
   ```

4. **Run Terraform Plan:**
   - The plan workflow will validate all required variables
   - Review the plan to see the RDS instance that will be created

5. **Run Terraform Apply:**
   - The RDS instance will be created (takes ~10-15 minutes)
   - Secrets Manager secret will be created automatically
   - Backup vault and plan will be configured
   - ECS services will use the new database

## Notes

- The RDS instance will be created in the same VPC as the ECS services, ensuring proper connectivity
- The security group automatically allows PostgreSQL (port 5432) traffic from ECS services
- Database username is sanitized to ensure it starts with a letter and contains only alphanumeric characters
- If username starts with a number, it's prefixed with "a"
- If username is empty, it defaults to "cardinalprod"


