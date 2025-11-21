# How GitHub Variables Flow to ECS Services

## Complete Flow

### Step 1: GitHub Variables → GitHub Actions
**Location:** `.github/workflows/USW2-Terraform-apply.yml`

```yaml
env:
  FRONTEND_IMAGE: ${{ vars.USW2_FRONTEND_IMAGE }}  # Gets: "develop-e86163776efc6e31edf1d8cb642a56288418959d"
  BACKEND_IMAGE: ${{ vars.USW2_BACKEND_IMAGE }}     # Gets: "develop-e86163776efc6e31edf1d8cb642a56288418959d"
```

### Step 2: GitHub Actions → Terraform Variables
**Location:** `.github/workflows/USW2-Terraform-apply.yml` (line 111-112)

```bash
echo "TF_VAR_frontend_image=$FRONTEND_IMAGE" >> "$GITHUB_ENV"
echo "TF_VAR_backend_image=$BACKEND_IMAGE" >> "$GITHUB_ENV"
```

**Result:**
- `TF_VAR_frontend_image = "develop-e86163776efc6e31edf1d8cb642a56288418959d"`
- `TF_VAR_backend_image = "develop-e86163776efc6e31edf1d8cb642a56288418959d"`

### Step 3: Terraform Variables → Image URI Construction
**Location:** `stacks/prod/main.tf` (lines 233, 269)

**Frontend:**
```hcl
image = startswith(var.frontend_image, "${data.aws_caller_identity.current.account_id}.dkr.ecr") 
  ? var.frontend_image  # If already full URI, use as-is
  : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}-frontend:${var.frontend_image}"
```

**Logic:**
- Input: `var.frontend_image = "develop-e86163776efc6e31edf1d8cb642a56288418959d"`
- Check: Does it start with `121577249019.dkr.ecr`? **NO**
- Result: Construct full URI
- **Final Image URI:** `121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:develop-e86163776efc6e31edf1d8cb642a56288418959d`

**Backend:**
- **Final Image URI:** `121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-backend:develop-e86163776efc6e31edf1d8cb642a56288418959d`

### Step 4: Image URI → ECS Task Definition
**Location:** `modules/ecs-service/main.tf` (line 82)

```hcl
container_definitions = jsonencode([{
  name  = var.container_name
  image = var.image  # Uses the constructed URI from Step 3
  ...
}])
```

### Step 5: ECS Task Definition → ECS Service
**Location:** `modules/ecs-service/main.tf` (line 118)

```hcl
task_definition = aws_ecs_task_definition.td.arn
```

## The Problem

✅ **What's Working:**
- GitHub variables are read correctly
- Terraform variables are set correctly
- Image URIs are constructed correctly
- Task definitions are created with correct image URIs
- ECS services are created

❌ **What's Missing:**
- **The actual Docker images don't exist in ECR yet!**
- ECS tries to pull: `121577249019.dkr.ecr.us-west-2.amazonaws.com/cardinal-frontend:develop-e86163776efc6e31edf1d8cb642a56288418959d`
- But ECR repository is empty → **Image pull fails** → **Tasks fail** → **Services show 0 tasks running**

## Solution

You need to **push the Docker images** to ECR with those exact tags. The images with tag `develop-e86163776efc6e31edf1d8cb642a56288418959d` must exist somewhere. You need to:

1. **Find where the images are** (another ECR, Docker Hub, CI/CD artifacts, etc.)
2. **Pull them**
3. **Tag them** with the ECR URI
4. **Push them** to ECR

## Where Are Your Images?

The tag `develop-e86163776efc6e31edf1d8cb642a56288418959d` suggests:
- These were built by a CI/CD pipeline
- They might be in another ECR repository
- They might be in a build artifact storage
- They might need to be built from source code

**Can you check:**
1. Do you have a CI/CD pipeline (GitHub Actions, Jenkins, etc.) that builds these images?
2. Where does that pipeline push the images?
3. Do you have the source code and Dockerfiles to build them?




