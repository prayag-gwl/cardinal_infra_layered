## Project Structure
- `modules/`: networking, alb, ecs-cluster, ecs-service, ecr, logging, rds, backup, monitoring, common
- `bootstrap/state-backend/`: remote state bucket + lock table bootstrap
- `.github/workflows/Bootstrap-state-backend.yml`: manual workflow to provision remote state
- `.github/workflows/Dev-Terraform-apply.yml`: plan + summary for `stacks/dev`
- `stacks/dev/`: lightweight dev services (requires existing networking)
- `stacks/prod/`: production environment (networking, dual ALBs, ECS, RDS, backups, monitoring)

### Flow
1. Run bootstrap workflow (or local stack) to create remote state → store values as GitHub secrets.
2. Push to `develop` → CI runs init/validate/plan in `stacks/dev` and reports plan summary (no apply).
3. For production deploys: run `stacks/prod` locally or via a gated workflow to provision networking, ALBs, ECS services, RDS, monitoring, and AWS Backup per the production recommendations.

