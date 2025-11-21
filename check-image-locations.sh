#!/bin/bash
# Script to check where images might be located

set -euo pipefail

TAG="develop-e86163776efc6e31edf1d8cb642a56288418959d"
REPOS=("cardinal-frontend" "cardinal-backend")
REGIONS=("us-west-1" "us-west-2" "us-east-1" "us-east-2" "eu-west-1" "ap-southeast-1")

echo "=========================================="
echo "Searching for images with tag: ${TAG}"
echo "=========================================="
echo ""

# Check all AWS regions
for region in "${REGIONS[@]}"; do
  echo "Checking region: ${region}"
  for repo in "${REPOS[@]}"; do
    result=$(aws ecr describe-images \
      --repository-name "${repo}" \
      --region "${region}" \
      --image-ids "imageTag=${TAG}" \
      2>/dev/null || echo "NOT_FOUND")
    
    if [ "$result" != "NOT_FOUND" ]; then
      echo "  ✅ FOUND: ${repo} in ${region}"
      echo "$result" | jq -r '.imageDetails[0] | "    URI: \(.repositoryName)@\(.imageDigest)"'
    else
      echo "  ❌ Not found: ${repo} in ${region}"
    fi
  done
  echo ""
done

# Check if repositories exist at all
echo "Checking if repositories exist in us-west-2:"
for repo in "${REPOS[@]}"; do
  repos=$(aws ecr describe-repositories --region us-west-2 2>/dev/null | jq -r '.repositories[].repositoryName' || echo "")
  if echo "$repos" | grep -q "^${repo}$"; then
    echo "  ✅ Repository exists: ${repo}"
    # List all tags in this repo
    tags=$(aws ecr list-images --repository-name "${repo}" --region us-west-2 2>/dev/null | jq -r '.imageIds[]?.imageTag // empty' | grep -v '^null$' || echo "")
    if [ -n "$tags" ]; then
      echo "    Available tags:"
      echo "$tags" | head -5 | sed 's/^/      - /'
      [ $(echo "$tags" | wc -l) -gt 5 ] && echo "      ... and more"
    else
      echo "    ⚠️  Repository is empty (no images)"
    fi
  else
    echo "  ❌ Repository does not exist: ${repo}"
  fi
done

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "If images were not found, you need to:"
echo "1. Build the images from source code, OR"
echo "2. Copy them from another location, OR"
echo "3. Use different image tags that exist"
echo ""




