resource "aws_ecr_repository" "repo" {
  for_each = toset(var.repository_names)
  name     = each.value
  tags     = var.tags
}
output "repositories" {
  value = { for k, r in aws_ecr_repository.repo : k => r.repository_url }
}
