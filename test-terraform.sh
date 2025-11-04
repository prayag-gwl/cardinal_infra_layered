#!/bin/bash
# Test Terraform files locally using Docker

set -e

TERRAFORM_VERSION="1.13.4"
WORK_DIR="/workspace"

echo "🧪 Testing Terraform configuration..."

# Test main stack
echo ""
echo "📁 Testing stacks/dev/main.tf..."
docker run --rm -v "$(pwd):$WORK_DIR" -w "$WORK_DIR/stacks/dev" \
  hashicorp/terraform:$TERRAFORM_VERSION \
  init -backend=false

docker run --rm -v "$(pwd):$WORK_DIR" -w "$WORK_DIR/stacks/dev" \
  hashicorp/terraform:$TERRAFORM_VERSION \
  validate

echo "✅ stacks/dev/main.tf is valid!"

# Test app stack
if [ -f "stacks/dev/app/main.tf" ]; then
  echo ""
  echo "📁 Testing stacks/dev/app/main.tf..."
  # Create a temporary terraform.tfvars for app stack in workspace
  cat > stacks/dev/app/terraform.tfvars <<EOF
aws_region            = "us-west-1"
project               = "cardinal"
environment           = "dev"
vpc_id                = "vpc-test"
public_subnet_ids     = ["subnet-test1", "subnet-test2"]
alb_security_group_id = "sg-test"
ecs_service_sg_id     = "sg-test"
frontend_image        = "test-image:latest"
EOF
  
  docker run --rm -v "$(pwd):$WORK_DIR" -w "$WORK_DIR/stacks/dev/app" \
    hashicorp/terraform:$TERRAFORM_VERSION \
    init -backend=false
  
  docker run --rm -v "$(pwd):$WORK_DIR" -w "$WORK_DIR/stacks/dev/app" \
    hashicorp/terraform:$TERRAFORM_VERSION \
    validate
  
  # Clean up test tfvars
  rm -f stacks/dev/app/terraform.tfvars
  
  echo "✅ stacks/dev/app/main.tf is valid!"
fi

# Test other stacks
for stack in network data cdn; do
  if [ -f "stacks/dev/$stack/main.tf" ]; then
    echo ""
    echo "📁 Testing stacks/dev/$stack/main.tf..."
    docker run --rm -v "$(pwd):$WORK_DIR" -w "$WORK_DIR/stacks/dev/$stack" \
      hashicorp/terraform:$TERRAFORM_VERSION \
      init -backend=false
    
    docker run --rm -v "$(pwd):$WORK_DIR" -w "$WORK_DIR/stacks/dev/$stack" \
      hashicorp/terraform:$TERRAFORM_VERSION \
      validate
    
    echo "✅ stacks/dev/$stack/main.tf is valid!"
  fi
done

echo ""
echo "🎉 All Terraform files are valid!"

