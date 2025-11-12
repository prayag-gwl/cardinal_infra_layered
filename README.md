## Cardinal Infra (Layered)
Terraform modules and environment stacks for AWS.

### Layout
- `modules/`: reusable modules (ALB, ECS cluster/service, ECR, logging, common).
- `stacks/dev/`: dev environment composition.
- `.github/workflows/Dev-Terraform-apply.yml`: CI plan/apply for `develop`.

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

