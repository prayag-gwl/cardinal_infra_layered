## Cardinal Infra (Layered)
Terraform modules and environment stacks for AWS.

### Layout
- `modules/`: reusable modules (ALB, ECS cluster/service, ECR, logging, common).
- `stacks/dev/`: dev environment composition.
- `.github/workflows/Dev-Terraform-apply.yml`: CI plan/apply for `develop`.
- `bootstrap/state-backend/`: one-time stack to provision the remote state bucket and lock table.

### Prereqs
- Terraform >= 1.5
- AWS role assumable by GitHub OIDC (`AWS_ROLE_ARN` secret).

### Local
```bash
cd stacks/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -auto-approve -var-file="terraform.tfvars"
```

### Remote state bootstrap

1. Provision the backend once (local run):
   ```bash
   cd bootstrap/state-backend
   terraform init
   terraform apply -auto-approve \
     -var 'bucket_name=<unique-bucket>' \
     -var 'dynamodb_table_name=tf-locks-dev'
   ```
   Add `-var 'enable_kms=true'` to create a dedicated KMS key.
2. Store the outputs as GitHub secrets consumed by `.github/workflows/Dev-Terraform-apply.yml`:
   - `TF_BACKEND_BUCKET`
   - `TF_BACKEND_KEY` (e.g. `envs/develop/terraform.tfstate`)
   - `TF_BACKEND_REGION`
   - `TF_BACKEND_DDB_TABLE`
   - `TF_BACKEND_KMS_KEY_ID` (only if KMS enabled)
3. Re-run the workflow. It will now initialize Terraform against the managed backend and only execute plan + summary.

