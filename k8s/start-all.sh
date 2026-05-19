#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# start-all.sh
# Bootstraps the full fiapstore stack on EKS.
# Uses RDS for all databases — no in-cluster postgres DB pods are created.
#
# Reads credentials from ${ROOT_DIR}/.env (gitignored).
#
# Usage:
#   ./start-all.sh
#   DOCKERHUB_USER=alangamedev ./start-all.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NS="fiapstore"

# Load environment variables from root .env if it exists
if [[ -f "${ROOT_DIR}/.env" ]]; then
  echo "Loading variables from ${ROOT_DIR}/.env..."
  set -a
  source "${ROOT_DIR}/.env"
  set +a
else
  echo "WARNING: ${ROOT_DIR}/.env not found. RDS connection strings will be empty."
fi

DOCKERHUB_USER="${DOCKERHUB_USER:-DOCKERHUB_USER}"

echo "=========================================="
echo " fiapstore :: starting Kubernetes stack"
echo " Namespace      : ${NS}"
echo " Dockerhub user : ${DOCKERHUB_USER}"
echo " Database       : RDS (AWS)"
echo "=========================================="

# -----------------------------------------------------------------------------
# Applies a deployment YAML replacing the DOCKERHUB_USER placeholder
# -----------------------------------------------------------------------------
apply_with_image_patch() {
  local file="$1"
  if [[ "${DOCKERHUB_USER}" != "DOCKERHUB_USER" ]]; then
    sed "s|DOCKERHUB_USER/|${DOCKERHUB_USER}/|g" "${file}" | kubectl apply -f -
  else
    kubectl apply -f "${file}"
  fi
}

# -----------------------------------------------------------------------------
# Creates (or updates) a K8s secret using RDS connection strings from .env
# -----------------------------------------------------------------------------
apply_secret() {
  local prefix="$1"
  local conn_str pg_pass pg_db

  case "$prefix" in
    catalog)
      conn_str="${DB_CONNECTION_STRING_CATALOG:-}"
      pg_pass="${CATALOG_PG_PASSWORD:-postgres}"
      pg_db="pg-catalog"
      ;;
    payments)
      conn_str="${DB_CONNECTION_STRING_PAYMENTS:-}"
      pg_pass="${PAYMENTS_PG_PASSWORD:-postgres}"
      pg_db="pg-payments"
      ;;
    users)
      conn_str="${DB_CONNECTION_STRING_USERS:-}"
      pg_pass="${USERS_PG_PASSWORD:-postgres}"
      pg_db="pg-users"
      ;;
    notifications)
      conn_str="${DB_CONNECTION_STRING_NOTIFICATIONS:-}"
      pg_pass="${NOTIFICATIONS_PG_PASSWORD:-postgres}"
      pg_db="pg-notifications"
      ;;
  esac

  local jwt_key="${JWT_KEY:-}"

  echo "  Applying ${prefix}-secret (RDS)..."

  local args=(
    --namespace "${NS}"
    --from-literal=ConnectionStrings__DefaultConnection="${conn_str}"
    --from-literal=Jwt__Key="${jwt_key}"
    --from-literal=POSTGRES_USER="postgres"
    --from-literal=POSTGRES_PASSWORD="${pg_pass}"
    --from-literal=POSTGRES_DB="${pg_db}"
  )

  # AWS credentials (free-tier account — shared by DynamoDB + Lambda across all services)
  args+=(
    --from-literal=AWS_ACCESS_KEY_ID="${LAMBDA_AWS_ACCESS_KEY_ID:-}"
    --from-literal=AWS_SECRET_ACCESS_KEY="${LAMBDA_AWS_SECRET_ACCESS_KEY:-}"
    --from-literal=AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-2}"
  )

  if [[ "$prefix" == "catalog" ]]; then
    args+=(
      --from-literal=ElasticSettings__ApiKey="${ELASTICSETTINGS__APIKEY:-}"
      --from-literal=ElasticSettings__CloudId="${ELASTICSETTINGS__CLOUDID:-}"
      --from-literal=ElasticSettings__UseCloud="${ELASTICSETTINGS__USECLOUD:-false}"
    )
  fi

  kubectl create secret generic "${prefix}-secret" "${args[@]}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

# -----------------------------------------------------------------------------
# Deploys one microservice (secret + configmap + api deployment + service + hpa)
# DB deployment/service are intentionally omitted — using RDS instead.
# -----------------------------------------------------------------------------
deploy_service() {
  local svc_dir="$1"
  local prefix="$2"

  echo ""
  echo ">> Deploying ${prefix}"
  apply_secret "${prefix}"
  kubectl apply -f "${svc_dir}/${prefix}-configmap.yaml"
  apply_with_image_patch "${svc_dir}/${prefix}-deployment.yaml"
  kubectl apply -f "${svc_dir}/${prefix}-service.yaml"
  kubectl apply -f "${svc_dir}/${prefix}-hpa.yaml"
}

echo ""
echo ">> [1/4] Creating namespace"
kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"

# Garantir StorageClass padrão no EKS (gp2)
if kubectl get storageclass gp2 >/dev/null 2>&1; then
  echo "Configurando gp2 como StorageClass padrão..."
  kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class="true" --overwrite || true
fi

echo ""
echo ">> [2/4] Deploying shared infrastructure (RabbitMQ & Redis)"
kubectl apply -f "${SCRIPT_DIR}/rabbitmq-deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/rabbitmq-service.yaml"
kubectl apply -f "${SCRIPT_DIR}/redis-deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/redis-service.yaml"

echo ""
echo ">> [3/4] Deploying microservices (connected to RDS)"
deploy_service "${ROOT_DIR}/usersapi/k8s"          "users"
deploy_service "${ROOT_DIR}/catalogapi/k8s"        "catalog"
deploy_service "${ROOT_DIR}/paymentsapi/k8s"       "payments"
deploy_service "${ROOT_DIR}/notificationsapi/k8s"  "notifications"

echo ""
echo ">> [4/4] Waiting for API deployments to become available (timeout 5m)"
for d in users-api catalog-api payments-api notifications-api; do
  kubectl rollout status deployment/"${d}" -n "${NS}" --timeout=5m || true
done

echo ""
echo "=========================================="
echo " fiapstore is up. Useful commands:"
echo "   kubectl get all -n ${NS}"
echo "   kubectl get hpa -n ${NS}"
echo "   kubectl get svc -n ${NS}   # LoadBalancer external IPs"
echo "=========================================="
