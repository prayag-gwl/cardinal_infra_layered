## Project Structure
- `modules/`: alb, ecs-cluster, ecs-service, ecr, logging, common
- `stacks/dev/`: network, data, app, cdn
- `.github/workflows/`: CI/CD

### Flow
Push to `develop` → CI runs init/validate/plan/apply in `stacks/dev` → ECS + ALB deploy FE service; CDN/data optional.

