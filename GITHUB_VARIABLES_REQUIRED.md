# Required GitHub Variables for USW1 (us-west-1) Deployment

This document lists all the ARN values and variables you need to add to GitHub repository variables/secrets for the develop branch deployment to us-west-1.

## Required Repository Variables (USW1_*)

### Infrastructure Configuration
- **USW1_PROJECT**: Project name (e.g., `cardinal`)
- **USW1_ENVIRONMENT**: Environment name (e.g., `prod`)
- **USW1_AWS_REGION**: AWS region (e.g., `us-west-1`)
- **USW1_VPC_CIDR**: VPC CIDR block (e.g., `10.0.0.0/16`)
- **USW1_AZS**: Comma-separated availability zones (e.g., `us-west-1a,us-west-1c`)
- **USW1_PUBLIC_SUBNET_CIDRS**: Comma-separated public subnet CIDRs (e.g., `10.0.1.0/24,10.0.3.0/24`)
- **USW1_PRIVATE_SUBNET_CIDRS**: Comma-separated private subnet CIDRs (e.g., `10.0.101.0/24,10.0.103.0/24`)
- **USW1_DATA_SUBNET_CIDRS**: (Optional) Comma-separated data subnet CIDRs

### Container Images
- **USW1_FRONTEND_IMAGE**: Frontend container image (e.g., `public.ecr.aws/.../frontend:tag` or just `tag`)
- **USW1_BACKEND_IMAGE**: Backend container image (e.g., `public.ecr.aws/.../backend:tag` or just `tag`)

### Database Configuration
- **USW1_DB_MASTER_USERNAME**: RDS master username
- **USW1_EXISTING_RDS_IDENTIFIER**: **REQUIRED** - Identifier of your existing RDS database instance (e.g., `cardinal-prod-db`)
- **USW1_DATABASE_SECRET_ARN**: **REQUIRED** - ARN of your existing Secrets Manager secret containing database credentials (e.g., `arn:aws:secretsmanager:us-west-1:123456789012:secret:cardinal/prod/db-abc123`)

### KMS Keys
- **USW1_DB_KMS_KEY_ARN**: (Optional) ARN of existing KMS key for RDS encryption (e.g., `arn:aws:kms:us-west-1:123456789012:key/abc123-def456`)
- **USW1_BACKUP_KMS_KEY_ARN**: (Optional) ARN of existing KMS key for backup vault encryption

### Certificates & Security
- **USW1_FRONTEND_CERTIFICATE_ARN**: (Optional) ACM certificate ARN for frontend ALB HTTPS
- **USW1_BACKEND_CERTIFICATE_ARN**: (Optional) ACM certificate ARN for backend ALB HTTPS
- **USW1_WAF_WEB_ACL_ARN**: (Optional) WAF Web ACL ARN

### Terraform Backend Configuration (Secrets)
- **USW1_TF_BACKEND_BUCKET**: S3 bucket name for Terraform state (already exists)
- **USW1_TF_BACKEND_KEY**: State file key (e.g., `envs/usw1/terraform.tfstate`)
- **USW1_TF_BACKEND_REGION**: Region for state backend (e.g., `us-west-1`)
- **USW1_TF_BACKEND_DDB_TABLE**: DynamoDB table name for state locking (already exists)
- **USW1_TF_BACKEND_KMS_KEY_ID**: (Optional) KMS key ID for state encryption

### AWS Authentication
- **USW1_AWS_ROLE_ARN**: IAM role ARN for GitHub Actions OIDC (e.g., `arn:aws:iam::123456789012:role/github-actions-usw1`)

## Required Repository Secrets (USW1_*)

- **USW1_DB_MASTER_PASSWORD**: RDS master password (sensitive)

## Summary of Existing Resources

The Terraform script now references these existing resources instead of creating them:

1. **RDS Database**: Uses `data.aws_db_instance` to reference existing database
   - Provide: `USW1_EXISTING_RDS_IDENTIFIER` (the database identifier/name)

2. **Secrets Manager**: Uses `data.aws_secretsmanager_secret` to reference existing secret
   - Provide: `USW1_DATABASE_SECRET_ARN` (full ARN of the secret)

3. **KMS Keys**: Already configured via variables
   - Provide: `USW1_DB_KMS_KEY_ARN` (if using existing KMS key for RDS)
   - Provide: `USW1_BACKUP_KMS_KEY_ARN` (if using existing KMS key for backup)

4. **S3 & DynamoDB**: Used for Terraform state backend (configured via secrets)
   - Provide: `USW1_TF_BACKEND_BUCKET`, `USW1_TF_BACKEND_DDB_TABLE`, etc.

## How to Find Your ARNs

### RDS Identifier
```bash
aws rds describe-db-instances --region us-west-1 --query 'DBInstances[*].[DBInstanceIdentifier]' --output table
```

### Secrets Manager ARN
```bash
aws secretsmanager list-secrets --region us-west-1 --query 'SecretList[?contains(Name, `cardinal`) || contains(Name, `prod`) || contains(Name, `db`)].{Name:Name,ARN:ARN}' --output table
```

### KMS Key ARN
```bash
aws kms list-keys --region us-west-1 --query 'Keys[*].KeyId' --output table
aws kms describe-key --key-id <key-id> --region us-west-1 --query 'KeyMetadata.Arn' --output text
```

### S3 Bucket Name
```bash
aws s3 ls | grep terraform
```

### DynamoDB Table Name
```bash
aws dynamodb list-tables --region us-west-1 --query 'TableNames[?contains(@, `terraform`) || contains(@, `lock`)]' --output table
```

## Notes

- All variables should be prefixed with `USW1_` for the us-west-1 region
- The `EXISTING_RDS_IDENTIFIER` is the database identifier (name), not the ARN
- The `DATABASE_SECRET_ARN` must be the full ARN of the Secrets Manager secret
- S3 and DynamoDB for Terraform state backend are already configured and should not be created by this stack




