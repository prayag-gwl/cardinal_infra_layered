## Cardinal Infra (Layered)
Terraform modules and environment stacks for AWS.

### Layout
- `modules/`: reusable modules (networking, ALB, ECS cluster/service, ECR, logging, RDS, backup, monitoring, common).
- `stacks/prod/`: production-grade stack (multi-AZ networking, dual ALBs, RDS, backups, monitoring).
- `.github/workflows/USW1-Terraform-plan.yml`: CI plan workflow for `us-west-1` production stack.
- `.github/workflows/USW1-Terraform-apply.yml`: CI apply workflow for `us-west-1` production stack.
- `.github/workflows/Bootstrap-state-backend.yml`: manual workflow to create/refresh remote state backend.
- `bootstrap/state-backend/`: one-time stack to provision the remote state bucket and lock table.

### Prereqs
- Terraform >= 1.5
- AWS role assumable by GitHub OIDC (`AWS_ROLE_ARN` secret).

### Production stack

The production stack provisions the full architecture described in `Cardinal_Prod_Infra_Plan.txt`:

- Multi-AZ VPC with public + private subnets, NAT gateways, flow logs.
- Public HTTPS ALB (frontend) + internal HTTPS ALB (backend) with WAF option and S3 access logs.
- ECS cluster with Fargate & Spot capacity providers, ECS Exec, target-tracking autoscaling (CPU 60%, Memory 70%), CloudWatch logging.
- ECR repositories, CloudWatch dashboards + alarms, SNS alerting.
- Amazon RDS PostgreSQL (multi-AZ, gp3, Performance Insights, KMS encryption, IAM auth).
- Secrets Manager secret for DB credentials.
- AWS Backup vault + plan (daily full, hourly incremental) with SNS notifications.

Required inputs (pass via `terraform.tfvars` or CLI):

```hcl
aws_region             = "us-west-1"
project                = "cardinal"
environment            = "prod"
azs                    = ["us-west-1a", "us-west-1c"]
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnet_cidrs   = ["10.0.101.0/24", "10.0.103.0/24"]
frontend_image         = "public.ecr.aws/<acct>/frontend:prod"
backend_image          = "public.ecr.aws/<acct>/backend:prod"
frontend_certificate_arn = "arn:aws:acm:us-west-1:123456789012:certificate/..."
backend_certificate_arn  = "arn:aws:acm:us-west-1:123456789012:certificate/..."
db_master_username     = "cardinal_admin"
db_master_password     = "super-secure-password"
alarm_emails           = ["alerts@example.com"]
```

Optional inputs:

- `backend_health_path`, `frontend_health_path`
- `waf_web_acl_arn` to attach an existing AWS WAFv2 Web ACL
- `db_kms_key_arn` to reuse a customer-managed CMK (otherwise one is created)
- `backup_copy_actions` for cross-region backup copies
- `frontend_env`, `backend_env` maps for container environment variables

Usage:

```bash
cd stacks/prod
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -auto-approve -var-file="terraform.tfvars"
```

Outputs include ALB DNS names, ECS service names, the RDS endpoint, the Secrets Manager ARN storing DB credentials, backup vault ARN, and the CloudWatch dashboard name.

### Remote state bootstrap

1. Provision the backend once, either locally or by running the manual workflow:
   - **GitHub Actions** → `Bootstrap Terraform Backend` → `Run workflow` (optionally enable KMS or force destroy via inputs), or
   - Local run via `bootstrap/state-backend` as shown below.
2. Store the outputs as GitHub secrets consumed by `.github/workflows/Dev-Terraform-apply.yml`:
   - `TF_BACKEND_BUCKET`
   - `TF_BACKEND_KEY` (e.g. `envs/develop/terraform.tfstate`)
   - `TF_BACKEND_REGION`
   - `TF_BACKEND_DDB_TABLE`
   - `TF_BACKEND_KMS_KEY_ID` (only if KMS enabled)
3. Re-run the workflow. It will now initialize Terraform against the managed backend and only execute plan + summary.

#### Local bootstrap run

```bash
cd bootstrap/state-backend
terraform init
terraform apply -auto-approve \
  -var 'bucket_name=<unique-bucket>' \
  -var 'dynamodb_table_name=tf-locks-dev' \
  -var 'region=us-west-1'
```
Add `-var 'enable_kms=true'` to create a dedicated KMS key.

After the backend bucket/table exist and secrets are configured, run:

- `Bootstrap Terraform Backend` workflow for one-time backend provisioning (completed).
- `USW1 Terraform Plan` workflow for CI `plan` validation.
- `USW1 Terraform Apply` workflow for production deployment to `us-west-1`.

