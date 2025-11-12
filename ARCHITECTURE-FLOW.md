## Project Structure
- `modules/`: alb, ecs-cluster, ecs-service, ecr, logging, common
- `bootstrap/state-backend/`: remote state bucket + lock table bootstrap
- `.github/workflows/Bootstrap-state-backend.yml`: manual bootstrap runner
- `stacks/dev/`: network, data, app, cdn
- `.github/workflows/`: CI/CD

### Flow
Run bootstrap workflow (or local stack) to create remote state → store values as GitHub secrets → Push to `develop` → CI runs init/validate/plan in `stacks/dev` and reports summary; CDN/data optional.

