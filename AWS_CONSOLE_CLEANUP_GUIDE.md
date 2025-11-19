# AWS Console Cleanup Guide - Remove Partially Created Resources

This guide helps you manually delete resources created by the failed Terraform apply from the AWS Console.

**Region:** `us-west-1`  
**Project:** `cardinal`  
**Environment:** `prod`

---

## 1. ECS (Elastic Container Service)

### ECS Cluster
1. Go to **ECS** → **Clusters**
2. Find: `cardinal-prod-cluster`
3. Click on it → **Delete Cluster** → Confirm

### ECS Task Definitions
1. Go to **ECS** → **Task Definitions**
2. Find and delete:
   - `cardinal-prod-frontend-task`
   - `cardinal-prod-backend-task`
3. For each: Click → **Delete** → Confirm

---

## 2. ECR (Elastic Container Registry)

### ECR Repositories
1. Go to **ECR** → **Repositories**
2. Find and delete (if they exist):
   - `cardinal-frontend-prod` (if created)
   - `cardinal-backend-prod` (if created)
   - `cardinal-backend` (if this was created instead)
3. For each: Click → **Delete** → Type repository name → Confirm

**Note:** If you have `cardinal-frontend` and `cardinal-backend` for dev, **DO NOT DELETE** those.

---

## 3. VPC and Networking

### NAT Gateways
1. Go to **VPC** → **NAT Gateways**
2. Find NAT gateways with names/tags containing `cardinal-prod`
3. For each: Click → **Actions** → **Delete NAT Gateway** → Confirm
4. **Wait for deletion** (can take a few minutes)

### Elastic IPs (EIPs)
1. Go to **EC2** → **Elastic IPs**
2. Find EIPs associated with the deleted NAT gateways
3. For each: Click → **Actions** → **Release Elastic IP addresses** → Confirm

### Subnets
1. Go to **VPC** → **Subnets**
2. Find subnets with names/tags containing `cardinal-prod`:
   - Public subnets: `cardinal-prod-public-*`
   - Private subnets: `cardinal-prod-private-*`
3. For each: Click → **Delete subnet** → Confirm

### Route Tables
1. Go to **VPC** → **Route Tables**
2. Find route tables with names/tags containing `cardinal-prod`
3. For each: Click → **Delete route table** → Confirm

### Internet Gateway
1. Go to **VPC** → **Internet Gateways**
2. Find: `cardinal-prod-igw` (or similar)
3. **First detach it:**
   - Click on it → **Actions** → **Detach from VPC** → Select VPC → Detach
4. Then: **Actions** → **Delete internet gateway** → Confirm

### Security Groups
1. Go to **VPC** → **Security Groups**
2. Find security groups with names containing `cardinal-prod`:
   - `cardinal-prod-alb-sg`
   - `cardinal-prod-internal-alb-sg`
   - `cardinal-prod-ecs-service-sg`
   - `cardinal-prod-rds-sg`
3. For each: Click → **Delete security group** → Confirm

### VPC
1. Go to **VPC** → **Your VPCs**
2. Find: `cardinal-prod-vpc` (or similar, check CIDR `10.10.0.0/16`)
3. **Make sure all resources are deleted first** (subnets, gateways, etc.)
4. Click → **Delete VPC** → Confirm

---

## 4. Application Load Balancer (ALB)

### Load Balancers
1. Go to **EC2** → **Load Balancers**
2. Find ALBs with names containing `cardinal-prod`:
   - `cardinal-prod-frontend-alb`
   - `cardinal-prod-backend-alb`
3. For each: Select → **Actions** → **Delete** → Confirm

### Target Groups
1. Go to **EC2** → **Target Groups**
2. Find target groups with names containing `cardinal-prod`
3. For each: Select → **Actions** → **Delete** → Confirm

---

## 5. S3 Buckets

### S3 Buckets
1. Go to **S3** → **Buckets**
2. Find buckets with names containing `cardinal-prod`:
   - `cardinal-prod-alb-logs-*` (random suffix)
   - `cardinal-prod-flow-logs-*` (random suffix)
3. For each:
   - Click on bucket → **Empty** → Type bucket name → **Empty**
   - Then: **Delete** → Type bucket name → **Delete bucket**

---

## 6. CloudWatch

### Log Groups
1. Go to **CloudWatch** → **Log groups**
2. Find and delete:
   - `/ecs/cardinal-prod-frontend`
   - `/ecs/cardinal-prod-backend`
   - `/aws/ecs/cardinal-prod-exec`
3. For each: Click → **Actions** → **Delete log group(s)** → Confirm

### Alarms
1. Go to **CloudWatch** → **Alarms**
2. Find alarms with names containing `cardinal-prod` or `cardinal-db`:
   - `cardinal-db-cpu-high`
   - `cardinal-db-low-storage`
   - `alb-5xx-errors` (if created)
3. For each: Select → **Actions** → **Delete** → Confirm

---

## 7. SNS (Simple Notification Service)

### SNS Topics
1. Go to **SNS** → **Topics**
2. Find: `cardinal-prod-alerts`
3. Click → **Delete** → Confirm

---

## 8. AWS Backup

### Backup Plans
1. Go to **AWS Backup** → **Backup plans**
2. Find backup plan for `cardinal-prod-db-backup-vault`
3. Click → **Delete** → Confirm

### Backup Vaults
1. Go to **AWS Backup** → **Backup vaults**
2. Find: `cardinal-prod-db-backup-vault`
3. **First delete all backups** (if any)
4. Then: Click → **Delete vault** → Confirm

---

## 9. KMS Keys

### KMS Keys
1. Go to **KMS** → **Customer managed keys**
2. Find keys with alias/name containing `cardinal-prod-db-backup-vault`
3. **First delete the alias:**
   - Click on key → **Aliases** tab → Delete alias
4. **Schedule key deletion:**
   - Click on key → **Key deletion** → **Schedule key deletion** → 7-30 days → Confirm

**Note:** KMS keys have a mandatory waiting period (7-30 days) before permanent deletion.

---

## 10. IAM Roles and Policies

### IAM Roles
1. Go to **IAM** → **Roles**
2. Find and delete roles with names containing `cardinal-prod`:
   - `cardinal-prod-frontend-task-exec`
   - `cardinal-prod-frontend-task-role`
   - `cardinal-prod-backend-task-exec`
   - `cardinal-prod-backend-task-role`
   - `cardinal-prod-db-backup-vault-backup-role`
3. For each: Click → **Delete role** → Confirm

**Note:** You may need to detach policies first if they're attached.

---

## 11. VPC Flow Logs

### Flow Logs
1. Go to **VPC** → **Flow logs**
2. Find flow log for `cardinal-prod-vpc`
3. Click → **Delete flow log** → Confirm

---

## Cleanup Order (Important!)

Delete resources in this order to avoid dependency errors:

1. **ECS Services** (if any were created)
2. **ECS Task Definitions**
3. **ECS Cluster**
4. **ALB Target Groups**
5. **ALB Load Balancers**
6. **NAT Gateways** (wait for completion)
7. **Elastic IPs** (after NAT gateways are deleted)
8. **Subnets**
9. **Route Tables**
10. **Internet Gateway** (detach first, then delete)
11. **Security Groups**
12. **VPC Flow Logs**
13. **VPC**
14. **S3 Buckets** (empty first, then delete)
15. **CloudWatch Log Groups**
16. **CloudWatch Alarms**
17. **SNS Topics**
18. **AWS Backup Plans and Vaults**
19. **KMS Keys** (schedule deletion)
20. **IAM Roles**
21. **ECR Repositories** (optional - only if you want to recreate them)

---

## Verification

After cleanup, verify nothing is left:

1. **EC2 Dashboard** → Check for any `cardinal-prod` resources
2. **VPC Dashboard** → Check for any `cardinal-prod` VPCs
3. **S3** → Check for any `cardinal-prod` buckets
4. **CloudWatch** → Check for any `cardinal-prod` log groups/alarms
5. **IAM** → Check for any `cardinal-prod` roles

---

## Quick Search Tips

In AWS Console, use the search/filter boxes to quickly find resources:
- Search for: `cardinal-prod`
- Filter by tags: `Project=cardinal`, `Environment=prod`

---

## After Cleanup

Once all resources are deleted:

1. ✅ Update GitHub variables (fix AZs to 2 zones)
2. ✅ Commit and push the code fixes
3. ✅ Re-run `USW1 Terraform Apply` workflow

The new apply should succeed with the corrected configuration!

