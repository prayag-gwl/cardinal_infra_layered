locals {
  tags = merge(
    {
      Project       = var.project
      Environment   = title(var.environment)
      ProvisionedBy = "Terraform"
      ManagedBy     = "DevOps Team"
    },
    var.extra_tags
  )
}
