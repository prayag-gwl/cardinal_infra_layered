#!/bin/bash
# Script to identify and delete PROD resources created by previous Terraform apply
# Run this script to see what resources exist before deletion

set -e

AWS_REGION="${AWS_REGION:-us-west-1}"
PROJECT="cardinal"
ENVIRONMENT="prod"

echo "=========================================="
echo "PROD Resources Cleanup Identification"
echo "=========================================="
echo "Region: $AWS_REGION"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== 1. ALB Resources ===${NC}"
echo "ALB Name: cardinal-prod-alb"
aws elbv2 describe-load-balancers --region $AWS_REGION --query "LoadBalancers[?contains(LoadBalancerName, 'cardinal-prod')].[LoadBalancerName,LoadBalancerArn,State.Code]" --output table 2>/dev/null || echo "No ALBs found or access denied"

echo ""
echo "Target Groups:"
aws elbv2 describe-target-groups --region $AWS_REGION --query "TargetGroups[?contains(TargetGroupName, 'cardinal-prod')].[TargetGroupName,TargetGroupArn,Port,Protocol]" --output table 2>/dev/null || echo "No target groups found or access denied"

echo ""
echo -e "${YELLOW}=== 2. ECS Resources ===${NC}"
echo "ECS Cluster:"
aws ecs list-clusters --region $AWS_REGION --query "clusterArns[?contains(@, 'cardinal-prod')]" --output table 2>/dev/null || echo "No clusters found or access denied"

echo ""
echo "ECS Services:"
aws ecs list-services --cluster "cardinal-prod-cluster" --region $AWS_REGION --output table 2>/dev/null || echo "Cluster not found or access denied"

echo ""
echo -e "${YELLOW}=== 3. Security Groups ===${NC}"
VPC_ID="vpc-0d55fd072ff0e07c6"
aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?contains(GroupName, 'cardinal-prod')].[GroupId,GroupName,Description]" --output table 2>/dev/null || echo "No security groups found or access denied"

echo ""
echo -e "${YELLOW}=== 4. CloudWatch Log Groups ===${NC}"
aws logs describe-log-groups --region $AWS_REGION --log-group-name-prefix "/ecs/cardinal-prod" --query "logGroups[*].[logGroupName]" --output table 2>/dev/null || echo "No log groups found or access denied"
aws logs describe-log-groups --region $AWS_REGION --log-group-name-prefix "/aws/ecs/cardinal-prod" --query "logGroups[*].[logGroupName]" --output table 2>/dev/null || echo "No log groups found or access denied"

echo ""
echo -e "${YELLOW}=== 5. ECR Repositories ===${NC}"
aws ecr describe-repositories --region $AWS_REGION --query "repositories[?contains(repositoryName, 'cardinal-prod')].[repositoryName,repositoryUri]" --output table 2>/dev/null || echo "No repositories found or access denied"

echo ""
echo -e "${YELLOW}=== 6. S3 Buckets (ALB Logs) ===${NC}"
aws s3 ls | grep "cardinal-prod.*alb-logs" || echo "No ALB log buckets found"

echo ""
echo -e "${YELLOW}=== 7. IAM Roles ===${NC}"
aws iam list-roles --query "Roles[?contains(RoleName, 'cardinal-prod')].[RoleName,Arn]" --output table 2>/dev/null || echo "No IAM roles found or access denied"

echo ""
echo -e "${YELLOW}=== 8. CloudWatch Alarms ===${NC}"
aws cloudwatch describe-alarms --region $AWS_REGION --alarm-name-prefix "cardinal-prod" --query "MetricAlarms[*].[AlarmName,AlarmDescription]" --output table 2>/dev/null || echo "No alarms found or access denied"

echo ""
echo -e "${YELLOW}=== 9. SNS Topics ===${NC}"
aws sns list-topics --region $AWS_REGION --query "Topics[?contains(TopicArn, 'cardinal-prod')].[TopicArn]" --output table 2>/dev/null || echo "No SNS topics found or access denied"

echo ""
echo -e "${YELLOW}=== 10. CloudWatch Dashboards ===${NC}"
aws cloudwatch list-dashboards --region $AWS_REGION --query "DashboardEntries[?contains(DashboardName, 'cardinal-prod')].[DashboardName]" --output table 2>/dev/null || echo "No dashboards found or access denied"

echo ""
echo -e "${GREEN}=== Summary ===${NC}"
echo "Review the resources above and delete them in the correct order."
echo ""
echo "Deletion Order:"
echo "1. ECS Services (must be stopped first)"
echo "2. ECS Cluster"
echo "3. ALB Target Groups"
echo "4. ALB Listeners"
echo "5. ALB"
echo "6. Security Groups (after ALB and ECS are deleted)"
echo "7. CloudWatch Log Groups"
echo "8. IAM Roles"
echo "9. S3 Buckets (ALB logs)"
echo "10. CloudWatch Alarms"
echo "11. SNS Topics"
echo "12. CloudWatch Dashboards"
echo "13. ECR Repositories (optional - keep if you want to preserve images)"

