#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# start-all.sh
# Bootstraps the full fiapstore stack on a local Kubernetes cluster
# (minikube / kind). Order:
#   1. namespace
#   2. shared infra (RabbitMQ)
#   3. per-service: secret -> configmap -> db -> api -> hpa
#   4. metrics-server check (required for HPA)
#
# Usage:
#   ./start-all.sh
#   DOCKERHUB_USER=alansilva ./start-all.sh   # patches image refs on the fly
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
fi

DOCKERHUB_USER="${DOCKERHUB_USER:-DOCKERHUB_USER}"

echo "=========================================="
echo " fiapstore :: starting Kubernetes stack"
echo " Namespace      : ${NS}"
echo " Dockerhub user : ${DOCKERHUB_USER}"
echo "=========================================="

apply_with_image_patch() {
  # If DOCKERHUB_USER is set to something other than the placeholder, replace
  # it in the manifest before applying. Otherwise apply as-is.
  local file="$1"
  if [[ "${DOCKERHUB_USER}" != "DOCKERHUB_USER" ]]; then
    sed "s|DOCKERHUB_USER/|${DOCKERHUB_USER}/|g" "${file}" | kubectl apply -f -
  else
    kubectl apply -f "${file}"
  fi
}

echo ""
echo ">> [1/5] Creating namespace"
kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"

# Garantir que exista uma StorageClass padrão no EKS (gp2)
if kubectl get storageclass gp2 >/dev/null 2>&1; then
  echo "Configurando gp2 como StorageClass padrão..."
  kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class="true" --overwrite || true
fi

echo ""
echo ">> [2/5] Deploying shared infrastructure (RabbitMQ & Redis)"
kubectl apply -f "${SCRIPT_DIR}/rabbitmq-deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/rabbitmq-service.yaml"
kubectl apply -f "${SCRIPT_DIR}/redis-deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/redis-service.yaml"

apply_secret_with_patch() {
  local file="$1"
  local prefix="$2"
  if [[ "${prefix}" == "catalog" ]]; then
    local apikey="${ELASTICSETTINGS__APIKEY:-}"
    local cloudid="${ELASTICSETTINGS__CLOUDID:-}"
    local usecloud="${ELASTICSETTINGS__USECLOUD:-true}"
    local aws_key="${LAMBDA_AWS_ACCESS_KEY_ID:-}"
    local aws_secret="${LAMBDA_AWS_SECRET_ACCESS_KEY:-}"
    local aws_region="${AWS_DEFAULT_REGION:-us-east-1}"
    
    echo "  Applying catalog-secret with dynamic ElasticSettings & AWS credentials placeholders..."
    sed -e "s|ELASTICSETTINGS_APIKEY_PLACEHOLDER|${apikey}|g" \
        -e "s|ELASTICSETTINGS_CLOUDID_PLACEHOLDER|${cloudid}|g" \
        -e "s|ELASTICSETTINGS_USECLOUD_PLACEHOLDER|${usecloud}|g" \
        -e "s|AWS_ACCESS_KEY_ID_PLACEHOLDER|${aws_key}|g" \
        -e "s|AWS_SECRET_ACCESS_KEY_PLACEHOLDER|${aws_secret}|g" \
        -e "s|AWS_DEFAULT_REGION_PLACEHOLDER|${aws_region}|g" \
        "${file}" | kubectl apply -f -
  else
    kubectl apply -f "${file}"
  fi
}

deploy_service() {
  local svc_dir="$1"
  local prefix="$2"

  echo ""
  echo ">> Deploying ${prefix} from ${svc_dir}"
  apply_secret_with_patch "${svc_dir}/${prefix}-secret.yaml" "${prefix}"
  kubectl apply -f "${svc_dir}/${prefix}-configmap.yaml"
  kubectl apply -f "${svc_dir}/${prefix}-db-deployment.yaml"
  kubectl apply -f "${svc_dir}/${prefix}-db-service.yaml"
  apply_with_image_patch "${svc_dir}/${prefix}-deployment.yaml"
  kubectl apply -f "${svc_dir}/${prefix}-service.yaml"
  kubectl apply -f "${svc_dir}/${prefix}-hpa.yaml"
}

echo ""
echo ">> [3/5] Deploying microservices"
deploy_service "${ROOT_DIR}/usersapi/k8s"          "users"
deploy_service "${ROOT_DIR}/catalogapi/k8s"        "catalog"
deploy_service "${ROOT_DIR}/paymentsapi/k8s"       "payments"
deploy_service "${ROOT_DIR}/notificationsapi/k8s"  "notifications"

echo ""
echo ">> [4/5] Waiting for API deployments to become available (timeout 5m)"
for d in users-api catalog-api payments-api notifications-api; do
  kubectl rollout status deployment/"${d}" -n "${NS}" --timeout=5m || true
done

echo ""
echo ">> [5/5] Verifying metrics-server (needed for HPA)"
if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  echo "metrics-server is installed."
else
  echo "WARNING: metrics-server is NOT installed. HPA will not scale."
  echo "  minikube : minikube addons enable metrics-server"
  echo "  kind     : kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
  echo "             (then patch with --kubelet-insecure-tls for kind)"
fi

echo ""
echo "=========================================="
echo " fiapstore is up. Useful commands:"
echo "   kubectl get all -n ${NS}"
echo "   kubectl get hpa -n ${NS}"
echo "   minikube tunnel    # to expose LoadBalancer services on macOS"
echo "=========================================="
