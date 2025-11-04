output "alb_dns_name"          { value = module.alb.dns_name }
output "ecs_cluster_name"      { value = module.ecs_cluster.name }
output "frontend_service_name" { value = module.frontend_service.service_name }
output "backend_service_name"  { value = module.backend_service.service_name }
