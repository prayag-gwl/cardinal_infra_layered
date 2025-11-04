resource "aws_ecs_cluster" "this" {
  name = var.name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}
output "id"   { value = aws_ecs_cluster.this.id }
output "name" { value = aws_ecs_cluster.this.name }
