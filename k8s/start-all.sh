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

echo ""
echo ">> [2/5] Deploying shared infrastructure (RabbitMQ)"
kubectl apply -f "${SCRIPT_DIR}/rabbitmq-deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/rabbitmq-service.yaml"

deploy_service() {
  local svc_dir="$1"
  local prefix="$2"

  echo ""
  echo ">> Deploying ${prefix} from ${svc_dir}"
  kubectl apply -f "${svc_dir}/${prefix}-secret.yaml"
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
