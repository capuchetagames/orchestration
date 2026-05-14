#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# build-and-push.sh
# Builds Docker images for all 4 microservices and pushes them to Docker Hub.
#
# Usage:
#   DOCKERHUB_USER=youruser ./build-and-push.sh
#   DOCKERHUB_USER=youruser TAG=v1.0.0 ./build-and-push.sh
#   DOCKERHUB_USER=youruser PUSH=false ./build-and-push.sh   # build only
# =============================================================================

DOCKERHUB_USER="${DOCKERHUB_USER:-}"
TAG="${TAG:-latest}"
PUSH="${PUSH:-true}"

if [[ -z "${DOCKERHUB_USER}" ]]; then
  echo "ERROR: DOCKERHUB_USER environment variable is required."
  echo "Example: DOCKERHUB_USER=alansilva ./build-and-push.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# service_name : context_path
SERVICES=(
  "users-api:${ROOT_DIR}/usersapi"
  "catalog-api:${ROOT_DIR}/catalogapi"
  "payments-api:${ROOT_DIR}/paymentsapi"
  "notifications-api:${ROOT_DIR}/notificationsapi"
)

echo "=========================================="
echo " Docker Hub user : ${DOCKERHUB_USER}"
echo " Tag             : ${TAG}"
echo " Push enabled    : ${PUSH}"
echo "=========================================="

if [[ "${PUSH}" == "true" ]]; then
  echo ""
  echo "Logging in to Docker Hub (use your Docker Hub credentials)..."
  docker login
fi

for entry in "${SERVICES[@]}"; do
  name="${entry%%:*}"
  ctx="${entry#*:}"
  image="${DOCKERHUB_USER}/${name}:${TAG}"

  echo ""
  echo "------------------------------------------"
  echo " Building ${image}"
  echo " Context : ${ctx}"
  echo "------------------------------------------"

  if [[ "${PUSH}" == "true" ]]; then
    # Build multi-platform image and push directly (buildx handles the manifest list)
    docker buildx build \
      --platform linux/amd64,linux/arm64 \
      -t "${image}" \
      -f "${ctx}/Dockerfile" \
      --push \
      "${ctx}"
  else
    # Build only for the local platform (no push)
    docker buildx build \
      --platform linux/amd64,linux/arm64 \
      -t "${image}" \
      -f "${ctx}/Dockerfile" \
      "${ctx}"
  fi
done

echo ""
echo "=========================================="
echo " All images built${PUSH:+ and pushed} successfully."
echo "=========================================="
