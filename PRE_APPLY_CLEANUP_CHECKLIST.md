# Pre-Terraform Apply Cleanup Checklist

This document lists all resources that need to be checked and potentially deleted before running Terraform apply to avoid conflicts.

## 🔴 CRITICAL - Must Delete Before Apply

### 1. AWS Backup
- **Backup Vault**: `cardinal-prod-db-backup-vault`
  - Location: AWS Console → AWS Backup → Backup vaults
  - Action: Delete recovery points first, then delete vault
  - **Status**: ✅ Already identified - needs deletion

### 2. ECR Repositories
- **Repositories**:
  - `cardinal-frontend-prod`
  - `cardinal-backend-prod`
  - Location: AWS Console → ECR → Repositories
  - Action: Delete repositories (images will be deleted too)
  - **Note**: If you want to keep images, push them elsewhere first

### 3. CloudWatch Log Groups
- **Log Groups**:
  - `/ecs/cardinal-prod-frontend`
  - `/ecs/cardinal-prod-backend`
  - `/aws/ecs/cardinal-prod-exec`
  - Location: AWS Console → CloudWatch → Log groups
  - Action: Delete log groups

### 4. ECS Services
- **Services**:
  - `cardinal-prod-frontend-service`
  - `cardinal-prod-backend-service`
  - Location: AWS Console → ECS → Clusters → `cardinal-prod-cluster` → Services
  - Action: 
    1. Update desired count to 0
    2. Wait for tasks to stop
    3. Delete services

### 5. ECS Task Definitions
- **Task Definitions**:
  - `cardinal-prod-frontend-task`
  - `cardinal-prod-backend-task`
  - Location: AWS Console → ECS → Task definitions
  - Action: Deregister task definitions (after services are deleted)
  - **Note**: Old revisions can be kept, but latest should be deregistered

### 6. Application Load Balancers (ALBs)
- **Load Balancers**:
  - `cardinal-prod-frontend-alb`
  - `cardinal-prod-backend-alb`
  - Location: AWS Console → EC2 → Load Balancers
  - Action: Delete load balancers (target groups will be deleted automatically)

### 7. Target Groups
- **Target Groups** (if not deleted with ALBs):
  - `cardinal-prod-frontend-alb-fe-*`
  - `cardinal-prod-backend-alb-be-*`
  - Location: AWS Console → EC2 → Target Groups
  - Action: Delete target groups

## 🟡 IMPORTANT - Should Check/Delete

### 8. ECS Cluster
- **Cluster**: `cardinal-prod-cluster`
  - Location: AWS Console → ECS → Clusters
  - Action: Delete cluster (only after all services are deleted)
  - **Note**: Cluster must be empty before deletion

### 9. S3 Buckets
- **Buckets** (with random suffix):
  - `cardinal-prod-alb-logs-*` (random 6-char suffix)
  - `cardinal-prod-flow-logs-*` (random 6-char suffix)
  - Location: AWS Console → S3 → Buckets
  - Action: 
    1. Empty bucket first (delete all objects)
    2. Delete bucket
  - **Note**: Look for buckets matching the pattern

### 10. VPC and Networking Resources
- **VPC**: `cardinal-prod-vpc` (or similar name)
  - Location: AWS Console → VPC → Your VPCs
  - **Sub-resources to delete first**:
    - NAT Gateways
    - Internet Gateway
    - VPC Endpoints (if any)
    - Security Groups (except default)
    - Route Tables (except main)
    - Network ACLs (except default)
    - Subnets
  - Action: Delete VPC (after all sub-resources are deleted)

### 11. Security Groups
- **Security Groups** (look for names containing "cardinal-prod"):
  - ALB security group
  - Internal ALB security group
  - ECS service security group
  - RDS security group (if created by Terraform)
  - Location: AWS Console → VPC → Security Groups
  - Action: Delete security groups (after resources using them are deleted)

### 12. Elastic IPs (EIPs)
- **Elastic IPs**: Associated with NAT Gateways
  - Location: AWS Console → EC2 → Elastic IPs
  - Action: Release Elastic IPs (after NAT Gateways are deleted)

### 13. IAM Roles
- **IAM Roles**:
  - `cardinal-prod-frontend-task-exec`
  - `cardinal-prod-frontend-task-role`
  - `cardinal-prod-backend-task-exec`
  - `cardinal-prod-backend-task-role`
  - `cardinal-prod-db-backup-vault-backup-role`
  - Location: AWS Console → IAM → Roles
  - Action: Delete roles (after policies are detached)

### 14. IAM Policies (Inline)
- **Inline Policies** (attached to roles above):
  - `cardinal-prod-frontend-task-secrets`
  - `cardinal-prod-backend-task-secrets`
  - `cardinal-prod-frontend-exec-secrets`
  - `cardinal-prod-backend-exec-secrets`
  - Location: AWS Console → IAM → Roles → [Role Name] → Permissions
  - Action: Delete inline policies (will be deleted with roles)

### 15. CloudWatch Alarms
- **Alarms**:
  - `cardinal-prod-frontend-service-cpu-high`
  - `cardinal-prod-frontend-service-memory-high`
  - `cardinal-prod-backend-service-cpu-high`
  - `cardinal-prod-backend-service-memory-high`
  - `cardinal-db-cpu-high`
  - `cardinal-db-low-storage`
  - `alb-5xx-errors`
  - Location: AWS Console → CloudWatch → Alarms
  - Action: Delete alarms

### 16. CloudWatch Dashboard
- **Dashboard**: `cardinal-prod-cluster-observability`
  - Location: AWS Console → CloudWatch → Dashboards
  - Action: Delete dashboard

### 17. SNS Topic
- **Topic**: `cardinal-prod-alerts`
  - Location: AWS Console → SNS → Topics
  - Action: Delete topic (after subscriptions are deleted)

### 18. SNS Subscriptions
- **Subscriptions**: Email subscriptions to `cardinal-prod-alerts`
  - Location: AWS Console → SNS → Topics → `cardinal-prod-alerts` → Subscriptions
  - Action: Delete subscriptions (before deleting topic)

### 19. AWS Backup Plan
- **Backup Plan**: `cardinal-prod-db-backup-plan`
  - Location: AWS Console → AWS Backup → Backup plans
  - Action: Delete backup plan (before deleting vault)

## 🟢 OPTIONAL - Can Keep (Not Created by Terraform)

### Resources You Should NOT Delete:
- ✅ **RDS Instance**: `cardinal-db` (existing, referenced by Terraform)
- ✅ **Secrets Manager Secret**: `cardinal/db-creds-*` (existing, referenced by Terraform)
- ✅ **KMS Key**: `ECS-Prod-KMS-Key` (existing, referenced by Terraform)
- ✅ **S3 State Bucket**: Your Terraform state bucket (needed for state)
- ✅ **DynamoDB State Table**: Your Terraform state table (needed for state)
- ✅ **ACM Certificates**: Your SSL certificates (referenced by Terraform)

## 📋 Quick Deletion Order

To avoid dependency issues, delete in this order:

1. **ECS Services** → Stop tasks, delete services
2. **ECS Task Definitions** → Deregister
3. **ALBs** → Delete (target groups auto-deleted)
4. **Target Groups** → Delete any remaining
5. **ECS Cluster** → Delete (must be empty)
6. **CloudWatch Alarms** → Delete
7. **CloudWatch Dashboard** → Delete
8. **SNS Subscriptions** → Delete
9. **SNS Topic** → Delete
10. **Backup Plan** → Delete
11. **Backup Vault Recovery Points** → Delete
12. **Backup Vault** → Delete
13. **IAM Roles** → Delete (after detaching policies)
14. **Security Groups** → Delete
15. **NAT Gateways** → Delete
16. **Elastic IPs** → Release
17. **Internet Gateway** → Detach and delete
18. **Subnets** → Delete
19. **Route Tables** → Delete (except main)
20. **VPC** → Delete
21. **S3 Buckets** → Empty and delete
22. **ECR Repositories** → Delete
23. **CloudWatch Log Groups** → Delete

## 🔍 How to Find Resources

### Using AWS Console:
1. Use the search bar in AWS Console to search for "cardinal-prod"
2. Filter by tags: Look for resources with tag `Project=cardinal` and `Environment=prod`

### Using AWS CLI:
```bash
# List all resources with "cardinal-prod" in name
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=cardinal Key=Environment,Values=prod \
  --region us-west-1
```

## ⚠️ Important Notes

1. **Backup First**: If you have important data in ECR images or S3 buckets, back them up first
2. **State File**: Make sure your Terraform state is backed up before cleanup
3. **Dependencies**: Some resources have dependencies - delete in the order specified
4. **Time Required**: Full cleanup may take 15-30 minutes
5. **Cost**: Some resources (NAT Gateways, ALBs) incur charges until deleted

## ✅ Verification

After cleanup, verify:
- No ECS clusters named `cardinal-prod-*`
- No ALBs named `cardinal-prod-*`
- No VPCs with tags `Project=cardinal, Environment=prod`
- No ECR repos named `cardinal-*-prod`
- No CloudWatch log groups starting with `/ecs/cardinal-prod-*`
- No backup vault named `cardinal-prod-db-backup-vault`

Then you're ready for a fresh Terraform apply! 🚀


