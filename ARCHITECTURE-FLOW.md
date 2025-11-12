## Project Structure
- `modules/`: alb, ecs-cluster, ecs-service, ecr, logging, common
- `bootstrap/state-backend/`: remote state bucket + lock table bootstrap
- `stacks/dev/`: network, data, app, cdn
- `.github/workflows/`: CI/CD

### Flow
Bootstrap remote state once → store values as GitHub secrets → Push to `develop` → CI runs init/validate/plan in `stacks/dev` and reports summary; CDN/data optional.

