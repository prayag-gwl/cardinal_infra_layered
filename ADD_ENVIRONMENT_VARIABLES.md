# How to Add Environment Variables to ECS Task Definitions

## Overview
Environment variables can be added to both frontend and backend ECS services. They are passed through Terraform variables and injected into the container at runtime.

## Where to Add Environment Variables

### Option 1: In `terraform.tfvars` (Recommended for Local Development)

Edit `stacks/prod/terraform.tfvars`:

```hcl
# Frontend environment variables
frontend_env = {
  NODE_ENV              = "production"
  API_URL               = "https://api.example.com"
  REACT_APP_API_BASE    = "https://api.example.com"
  CUSTOM_VAR            = "custom_value"
  # Add more variables as needed
}

# Backend environment variables
backend_env = {
  NODE_ENV              = "production"
  DATABASE_URL          = "postgresql://user:pass@host:5432/db"
  REDIS_URL             = "redis://redis.example.com:6379"
  API_KEY               = "your-api-key"
  # Add more variables as needed
}
```

### Option 2: In GitHub Repository Variables (For CI/CD)

For GitHub Actions deployments, add environment variables as repository variables:

1. Go to **GitHub Repository** → **Settings** → **Secrets and variables** → **Actions** → **Variables**
2. Add new variables:

**For Frontend:**
- Variable name: `USW2_FRONTEND_ENV`
- Value: JSON format (see below)

**For Backend:**
- Variable name: `USW2_BACKEND_ENV`
- Value: JSON format (see below)

**JSON Format Example:**
```json
{
  "NODE_ENV": "production",
  "API_URL": "https://api.example.com",
  "REACT_APP_API_BASE": "https://api.example.com"
}
```

Then update `.github/workflows/USW2-Terraform-apply.yml` to export these variables.

### Option 3: Directly in `stacks/prod/main.tf` (Not Recommended)

You can also add them directly in the module call, but this is less flexible:

```hcl
module "frontend_service" {
  # ... other config ...
  environment_vars = {
    NODE_ENV = "production"
    API_URL  = "https://api.example.com"
  }
}
```

## Current Configuration

### Frontend Service
- **Variable:** `var.frontend_env` (line 310 in `stacks/prod/main.tf`)
- **Type:** `map(string)`
- **Default:** `{}` (empty)

### Backend Service
- **Variable:** `var.backend_env` (line 346 in `stacks/prod/main.tf`)
- **Type:** `map(string)`
- **Default:** `{}` (empty)

## How It Works

1. Environment variables are defined in `terraform.tfvars` or GitHub variables
2. Passed to the ECS service module via `environment_vars` parameter
3. Converted to ECS task definition format in `modules/ecs-service/main.tf` (line 108):
   ```hcl
   environment = [for k, v in var.environment_vars : { name = k, value = v }]
   ```
4. Injected into containers at runtime

## Example: Adding New Variables

### Step 1: Edit `terraform.tfvars`

```hcl
frontend_env = {
  NODE_ENV           = "production"
  REACT_APP_API_URL  = "https://api.example.com"
  REACT_APP_VERSION  = "1.0.0"
}

backend_env = {
  NODE_ENV           = "production"
  DATABASE_POOL_SIZE = "10"
  LOG_LEVEL          = "info"
  JWT_SECRET         = "your-secret-key"
}
```

### Step 2: Apply Changes

```bash
cd stacks/prod
terraform plan
terraform apply
```

### Step 3: Force New Deployment (if services already exist)

```bash
aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-frontend-service \
  --force-new-deployment \
  --region us-west-2

aws ecs update-service \
  --cluster cardinal-prod-usw2-cluster \
  --service cardinal-prod-usw2-backend-service \
  --force-new-deployment \
  --region us-west-2
```

## Sensitive Variables

For sensitive values (API keys, passwords, etc.), use **Secrets Manager** instead of environment variables:

1. Store in AWS Secrets Manager
2. Reference in the `secrets` parameter (already configured for database credentials)
3. Add to `local.db_secret_suffixes` if needed, or create new secret references

Example:
```hcl
secrets = [
  {
    name      = "API_KEY"
    value_from = "arn:aws:secretsmanager:us-west-2:121577249019:secret:my-secret:API_KEY::"
  }
]
```

## Verification

After adding environment variables:

1. **Check Task Definition:**
   ```bash
   aws ecs describe-task-definition \
     --task-definition cardinal-prod-usw2-frontend-task \
     --region us-west-2 \
     --query 'taskDefinition.containerDefinitions[0].environment'
   ```

2. **Check Running Container:**
   ```bash
   # Get task ID
   TASK_ID=$(aws ecs list-tasks \
     --cluster cardinal-prod-usw2-cluster \
     --service-name cardinal-prod-usw2-frontend-service \
     --region us-west-2 \
     --query 'taskArns[0]' \
     --output text | cut -d'/' -f3)
   
   # Execute command in container
   aws ecs execute-command \
     --cluster cardinal-prod-usw2-cluster \
     --task $TASK_ID \
     --container cardinal-frontend \
     --command "env" \
     --interactive \
     --region us-west-2
   ```

## Important Notes

- ✅ Environment variables are visible in task definitions (not encrypted)
- ✅ Use Secrets Manager for sensitive data
- ✅ Changes require new task definition and deployment
- ✅ Variables are available at container startup
- ✅ No restart needed - new tasks will have new variables

## File Locations Summary

| Purpose | File | Line |
|---------|------|------|
| Variable definition | `stacks/prod/variables.tf` | 50, 56 |
| Frontend usage | `stacks/prod/main.tf` | 310 |
| Backend usage | `stacks/prod/main.tf` | 346 |
| Task definition | `modules/ecs-service/main.tf` | 108 |
| Local values | `stacks/prod/terraform.tfvars` | (add here) |




