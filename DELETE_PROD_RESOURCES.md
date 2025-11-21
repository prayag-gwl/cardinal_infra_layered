# Step-by-Step Guide: Delete PROD Resources

This guide will help you delete all PROD resources created by the previous Terraform apply before running the new configuration.

## ⚠️ Important Notes

1. **Backup First**: Make sure you have backups of any important data
2. **Order Matters**: Resources must be deleted in the correct order due to dependencies
3. **Verify**: Double-check resource names before deletion
4. **No RDS/Backup Deletion**: Do NOT delete RDS or Backup resources (they are shared with DEV)

---

## 📋 Step-by-Step Deletion Process

### Step 1: Identify Resources

First, run the identification script to see what exists:

```bash
chmod +x cleanup-prod-resources.sh
./cleanup-prod-resources.sh
```

Or manually check each resource type (see commands below).

---

### Step 2: Delete ECS Services (MUST BE FIRST)

ECS services must be stopped before other resources can be deleted.

```bash
AWS_REGION="us-west-1"
CLUSTER_NAME="cardinal-prod-cluster"

# List services
aws ecs list-services --cluster $CLUSTER_NAME --region $AWS_REGION

# Delete frontend service
aws ecs update-service --cluster $CLUSTER_NAME --service "cardinal-prod-frontend" \
  --desired-count 0 --region $AWS_REGION

aws ecs delete-service --cluster $CLUSTER_NAME --service "cardinal-prod-frontend" \
  --region $AWS_REGION

# Delete backend service
aws ecs update-service --cluster $CLUSTER_NAME --service "cardinal-prod-backend" \
  --desired-count 0 --region $AWS_REGION

aws ecs delete-service --cluster $CLUSTER_NAME --service "cardinal-prod-backend" \
  --region $AWS_REGION

# Wait for services to be deleted (check status)
aws ecs describe-services --cluster $CLUSTER_NAME \
  --services "cardinal-prod-frontend" "cardinal-prod-backend" \
  --region $AWS_REGION --query "services[*].[serviceName,status]"
```

**Wait until both services show status "INACTIVE" before proceeding.**

---

### Step 3: Delete ECS Cluster

```bash
# Delete the cluster
aws ecs delete-cluster --cluster $CLUSTER_NAME --region $AWS_REGION

# Verify deletion
aws ecs describe-clusters --clusters $CLUSTER_NAME --region $AWS_REGION
```

---

### Step 4: Delete ALB Target Groups

```bash
# List target groups
aws elbv2 describe-target-groups --region $AWS_REGION \
  --query "TargetGroups[?contains(TargetGroupName, 'cardinal-prod')].[TargetGroupName,TargetGroupArn]"

# Delete frontend target group
aws elbv2 delete-target-group \
  --target-group-arn <TARGET_GROUP_ARN> \
  --region $AWS_REGION

# Delete backend target group
aws elbv2 delete-target-group \
  --target-group-arn <TARGET_GROUP_ARN> \
  --region $AWS_REGION
```

**Note**: Replace `<TARGET_GROUP_ARN>` with actual ARNs from the list command.

---

### Step 5: Delete ALB Listeners

```bash
ALB_ARN=$(aws elbv2 describe-load-balancers --region $AWS_REGION \
  --names "cardinal-prod-alb" --query "LoadBalancers[0].LoadBalancerArn" --output text)

# List listeners
aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --region $AWS_REGION

# Delete HTTPS listener (port 443)
aws elbv2 delete-listener \
  --listener-arn <HTTPS_LISTENER_ARN> \
  --region $AWS_REGION

# Delete HTTP listener (port 80)
aws elbv2 delete-listener \
  --listener-arn <HTTP_LISTENER_ARN> \
  --region $AWS_REGION
```

**Note**: Replace `<HTTPS_LISTENER_ARN>` and `<HTTP_LISTENER_ARN>` with actual ARNs.

---

### Step 6: Delete ALB

```bash
# Delete the ALB
aws elbv2 delete-load-balancer \
  --load-balancer-arn $ALB_ARN \
  --region $AWS_REGION

# Verify deletion
aws elbv2 describe-load-balancers --region $AWS_REGION \
  --query "LoadBalancers[?contains(LoadBalancerName, 'cardinal-prod')]"
```

---

### Step 7: Delete Security Groups

**⚠️ Important**: Only delete PROD-specific security groups. Do NOT delete:
- `cardinal-rds-sg` (shared with DEV)
- Any other shared security groups

```bash
VPC_ID="vpc-0d55fd072ff0e07c6"

# List PROD security groups
aws ec2 describe-security-groups --region $AWS_REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?contains(GroupName, 'cardinal-prod')].[GroupId,GroupName]"

# Delete PROD ALB security group
aws ec2 delete-security-group \
  --group-id <ALB_SG_ID> \
  --region $AWS_REGION

# Delete PROD ECS security group
aws ec2 delete-security-group \
  --group-id <ECS_SG_ID> \
  --region $AWS_REGION
```

**Note**: Replace `<ALB_SG_ID>` and `<ECS_SG_ID>` with actual security group IDs.

---

### Step 8: Delete CloudWatch Log Groups

```bash
# List log groups
aws logs describe-log-groups --region $AWS_REGION \
  --log-group-name-prefix "/ecs/cardinal-prod"

# Delete log groups
aws logs delete-log-group \
  --log-group-name "/ecs/cardinal-prod-frontend" \
  --region $AWS_REGION

aws logs delete-log-group \
  --log-group-name "/ecs/cardinal-prod-backend" \
  --region $AWS_REGION

aws logs delete-log-group \
  --log-group-name "/aws/ecs/cardinal-prod-exec" \
  --region $AWS_REGION
```

---

### Step 9: Delete IAM Roles

```bash
# List PROD IAM roles
aws iam list-roles --query "Roles[?contains(RoleName, 'cardinal-prod')].[RoleName,Arn]"

# Delete task execution roles
aws iam delete-role --role-name "cardinal-prod-frontend-task-exec"
aws iam delete-role --role-name "cardinal-prod-backend-task-exec"

# Delete task roles (if they exist)
aws iam list-roles --query "Roles[?contains(RoleName, 'cardinal-prod') && contains(RoleName, 'task')].[RoleName]"
# Delete any task roles found
```

**Note**: You may need to detach policies first:
```bash
aws iam list-attached-role-policies --role-name <ROLE_NAME>
aws iam detach-role-policy --role-name <ROLE_NAME> --policy-arn <POLICY_ARN>
```

---

### Step 10: Delete S3 Buckets (ALB Logs)

```bash
# List ALB log buckets
aws s3 ls | grep "cardinal-prod.*alb-logs"

# Empty the bucket first
aws s3 rm s3://<BUCKET_NAME> --recursive

# Delete the bucket
aws s3 rb s3://<BUCKET_NAME>
```

**Note**: Replace `<BUCKET_NAME>` with actual bucket name.

---

### Step 11: Delete CloudWatch Alarms

```bash
# List alarms
aws cloudwatch describe-alarms --region $AWS_REGION \
  --alarm-name-prefix "cardinal-prod" \
  --query "MetricAlarms[*].AlarmName"

# Delete alarms (replace with actual alarm names)
aws cloudwatch delete-alarms --region $AWS_REGION \
  --alarm-names "cardinal-prod-frontend-cpu-high" "cardinal-prod-backend-cpu-high" \
  "cardinal-prod-frontend-memory-high" "cardinal-prod-backend-memory-high"
```

---

### Step 12: Delete SNS Topics

```bash
# List topics
aws sns list-topics --region $AWS_REGION \
  --query "Topics[?contains(TopicArn, 'cardinal-prod')].[TopicArn]"

# Delete topic
aws sns delete-topic \
  --topic-arn <TOPIC_ARN> \
  --region $AWS_REGION
```

---

### Step 13: Delete CloudWatch Dashboards

```bash
# List dashboards
aws cloudwatch list-dashboards --region $AWS_REGION \
  --query "DashboardEntries[?contains(DashboardName, 'cardinal-prod')].[DashboardName]"

# Delete dashboard
aws cloudwatch delete-dashboards --region $AWS_REGION \
  --dashboard-names "cardinal-prod-dashboard"
```

---

### Step 14: ECR Repositories (Optional)

**⚠️ Keep these if you want to preserve container images!**

```bash
# List repositories
aws ecr describe-repositories --region $AWS_REGION \
  --query "repositories[?contains(repositoryName, 'cardinal-prod')].[repositoryName]"

# If you want to delete (WARNING: This deletes all images!)
aws ecr delete-repository --repository-name "cardinal-frontend-prod" \
  --force --region $AWS_REGION

aws ecr delete-repository --repository-name "cardinal-backend-prod" \
  --force --region $AWS_REGION
```

---

## ✅ Verification

After deletion, verify all resources are gone:

```bash
# Run the identification script again
./cleanup-prod-resources.sh
```

All PROD resources should show as "not found" or empty.

---

## 🚫 DO NOT DELETE

These resources are shared with DEV and should NOT be deleted:

- ✅ VPC: `cardinal-vpc` (vpc-0d55fd072ff0e07c6)
- ✅ Subnets (public and private)
- ✅ RDS Instance: `cardinal-db`
- ✅ RDS Security Group: `cardinal-rds-sg`
- ✅ Backup Vault and Plan (if using existing)
- ✅ Secrets Manager secrets (if shared)

---

## 🔄 After Cleanup

Once all resources are deleted:

1. **Verify Terraform state**: Check if Terraform state file exists
2. **Clean Terraform state** (if needed):
   ```bash
   cd stacks/prod
   terraform destroy -auto-approve
   ```
3. **Run new Terraform apply** with updated configuration

---

## 📝 Quick Reference: Resource Names

Based on the PROD configuration:

- **ALB**: `cardinal-prod-alb`
- **Target Groups**: 
  - `tg-cardinal-prod-frontend-3000`
  - `tg-cardinal-prod-backend-3000`
- **ECS Cluster**: `cardinal-prod-cluster`
- **ECS Services**: 
  - `cardinal-prod-frontend`
  - `cardinal-prod-backend`
- **Security Groups**: 
  - `cardinal-prod-alb-sg`
  - `cardinal-prod-ecs-sg`
- **Log Groups**: 
  - `/ecs/cardinal-prod-frontend`
  - `/ecs/cardinal-prod-backend`
  - `/aws/ecs/cardinal-prod-exec`
- **IAM Roles**: 
  - `cardinal-prod-frontend-task-exec`
  - `cardinal-prod-backend-task-exec`
- **S3 Bucket**: `cardinal-prod-alb-logs-*` (with random suffix)
- **SNS Topic**: `cardinal-prod-alerts`
- **CloudWatch Dashboard**: `cardinal-prod-dashboard`

