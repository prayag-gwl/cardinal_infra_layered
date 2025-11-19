# Terraform Apply Errors - Fix Guide

> **⚠️ IMPORTANT:** Before fixing the errors, you need to clean up the partially created resources from the previous failed apply.  
> See **[AWS_CONSOLE_CLEANUP_GUIDE.md](./AWS_CONSOLE_CLEANUP_GUIDE.md)** for step-by-step instructions.

## Errors Found in Apply Logs

### 1. ✅ FIXED: Duplicate CloudWatch Log Group
**Error:**
```
Error: creating CloudWatch Logs Log Group (/aws/ecs/cardinal-prod-exec): ResourceAlreadyExistsException
```

**Root Cause:** The log group `/aws/ecs/cardinal-prod-exec` was being created twice:
- Once in the `logging` module
- Once as a standalone resource `aws_cloudwatch_log_group.ecs_exec`

**Fix Applied:** Removed the duplicate standalone resource. The log group is now only created by the `logging` module.

---

### 2. ⚠️ REQUIRES MANUAL ACTION: ECR Repository Already Exists
**Error:**
```
Error: creating ECR Repository (cardinal-frontend-prod): RepositoryAlreadyExistsException
```

**Root Cause:** The ECR repositories `cardinal-frontend-prod` and `cardinal-backend-prod` already exist in your AWS account.

**Solution:** Import existing ECR repositories into Terraform state:

```bash
cd stacks/prod
terraform init
terraform import 'module.ecr.aws_ecr_repository.repo["cardinal-frontend-prod"]' cardinal-frontend-prod
terraform import 'module.ecr.aws_ecr_repository.repo["cardinal-backend-prod"]' cardinal-backend-prod
```

**Note:** If the repositories have different names (e.g., `cardinal-frontend` without `-prod`), you'll need to either:
- Rename them in AWS to match the new naming convention, or
- Update the Terraform code to match existing names

**Alternative:** If you don't want Terraform to manage these repositories, you can remove the `ecr` module from `stacks/prod/main.tf` and use data sources instead.

---

### 3. ⚠️ REQUIRES GITHUB VARIABLE UPDATE: Invalid Availability Zone
**Error:**
```
Error: creating EC2 Subnet: InvalidParameterValue: Value (***b) for parameter availabilityZone is invalid. 
Subnets can currently only be created in the following availability zones: ***a, ***c.
```

**Root Cause:** The `USW1_AZS` GitHub variable is set to 3 availability zones (`us-west-1a`, `us-west-1b`, `us-west-1c`), but `us-west-1` only has 2 AZs available: `us-west-1a` and `us-west-1c`.

**Solution:** Update the `USW1_AZS` GitHub variable to only include 2 AZs:

1. Go to GitHub Repository → Settings → Secrets and variables → Actions → Variables
2. Find `USW1_AZS`
3. Update the value to: `["us-west-1a","us-west-1c"]` (JSON array format)

**Also update these related variables:**
- `USW1_PUBLIC_SUBNET_CIDRS`: Should have 2 CIDRs (one per AZ)
- `USW1_PRIVATE_SUBNET_CIDRS`: Should have 2 CIDRs (one per AZ)

Example:
- `USW1_PUBLIC_SUBNET_CIDRS`: `["10.10.0.0/22","10.10.4.0/22"]`
- `USW1_PRIVATE_SUBNET_CIDRS`: `["10.10.12.0/22","10.10.16.0/22"]`

---

### 4. ⚠️ REQUIRES AWS ACCOUNT ACTION: EIP Limit Exceeded
**Error:**
```
Error: creating EC2 EIP: AddressLimitExceeded: The maximum number of addresses has been reached.
```

**Root Cause:** Your AWS account has reached the default limit of 5 Elastic IP addresses per region. The Terraform script tries to create 3 NAT gateways (one per AZ), each requiring an EIP.

**Solutions:**

**Option A: Reduce NAT Gateways (Recommended)**
Since `us-west-1` only has 2 AZs, we should only create 2 NAT gateways. However, the networking module creates NAT gateways based on the number of AZs. With the AZ fix above (using only 2 AZs), this should automatically resolve.

**Option B: Request EIP Limit Increase**
1. Go to AWS Support Center
2. Request a service limit increase for "EC2-VPC Elastic IPs"
3. Request increase to at least 10 EIPs for `us-west-1`

**Option C: Release Unused EIPs**
1. Go to EC2 Console → Elastic IPs
2. Identify and release any unused EIPs
3. Ensure you have at least 2 free EIPs for NAT gateways

---

## Summary of Actions Required

1. ✅ **Fixed in code:** Duplicate CloudWatch log group
2. 🔧 **Manual import needed:** Import existing ECR repositories
3. 🔧 **Update GitHub variable:** Change `USW1_AZS` to use only 2 AZs
4. 🔧 **Update GitHub variables:** Adjust subnet CIDRs to match 2 AZs
5. 🔧 **AWS account:** Ensure you have at least 2 free EIPs (or request limit increase)

---

## After Fixes, Re-run Apply

Once you've completed the above steps:

1. Import ECR repositories (if needed)
2. Update GitHub variables for AZs and subnets
3. Re-run the `USW1 Terraform Apply` workflow

The apply should succeed after these fixes.

