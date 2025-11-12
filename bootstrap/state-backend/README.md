# Terraform State Backend Bootstrap

Provision the remote state backend (S3 bucket + DynamoDB lock table) that the main `stacks/dev` configuration depends on. This stack is intentionally small and uses local state so it can run **before** remote state exists.

You can execute it locally or trigger the GitHub Actions workflow `Bootstrap Terraform Backend`, which wraps the same commands and reads values from repository secrets.

## Inputs

Update `terraform.tfvars` or supply variables on the command line:

| Variable | Description |
| --- | --- |
| `bucket_name` | S3 bucket to store Terraform state (must be globally unique). |
| `bucket_force_destroy` | Set to `true` only if you need Terraform to delete the bucket even when objects exist. |
| `dynamodb_table_name` | DynamoDB table name for state locking (e.g. `tf-locks-dev`). |
| `region` | AWS region for all resources (defaults to `us-east-1`). |
| `enable_kms` | `true` to create a dedicated KMS key for bucket encryption. |
| `kms_alias` | Alias for the created KMS key (defaults to `tf-state-backend`). |
| `tags` | Optional map of tags to apply to every resource. |

## Usage

```bash
cd bootstrap/state-backend
terraform init
terraform plan -var 'bucket_name=<unique-bucket>' \
               -var 'dynamodb_table_name=tf-locks-dev'
terraform apply -auto-approve \
  -var 'bucket_name=<unique-bucket>' \
  -var 'dynamodb_table_name=tf-locks-dev'
```

If you enabled KMS, configure the main workflow backend with the emitted `kms_key_arn` (or alias) along with the bucket, key, region, and DynamoDB table outputs.

After running this bootstrap stack once, update the GitHub Actions workflow secrets to provide those values to the `terraform init` step in `.github/workflows/Dev-Terraform-apply.yml`.

