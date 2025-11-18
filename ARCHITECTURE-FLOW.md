## Project Structure
- `modules/`: networking, alb, ecs-cluster, ecs-service, ecr, logging, rds, backup, monitoring, common
- `bootstrap/state-backend/`: remote state bucket + lock table bootstrap
- `.github/workflows/Bootstrap-state-backend.yml`: manual workflow to provision remote state
- `.github/workflows/USW1-Terraform-plan.yml`: plan workflow for `us-west-1` production stack
- `.github/workflows/USW1-Terraform-apply.yml`: apply workflow for `us-west-1` production stack
- `stacks/prod/`: production environment (networking, dual ALBs, ECS, RDS, backups, monitoring)

### Flow
1. Run bootstrap workflow (or local stack) to create remote state → store values as GitHub secrets.
2. Push to `develop` branch → CI runs `USW1 Terraform Plan` to validate infrastructure changes.
3. For production deploys: run `USW1 Terraform Apply` workflow (or manually via `stacks/prod`) to provision networking, ALBs, ECS services, RDS, monitoring, and AWS Backup per the production recommendations.

