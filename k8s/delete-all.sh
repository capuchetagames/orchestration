#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# delete-all.sh
# Tears down the entire fiapstore stack. Drops the namespace, which cascades
# the deletion of all Deployments, Services, ConfigMaps, Secrets, HPAs and
# PVCs inside it.
#
# Usage:
#   ./delete-all.sh
#   KEEP_PVC=true ./delete-all.sh   # delete workloads but keep DB volumes
# =============================================================================

NS="fiapstore"
KEEP_PVC="${KEEP_PVC:-false}"

echo "=========================================="
echo " fiapstore :: tearing down stack"
echo " Namespace : ${NS}"
echo " KEEP_PVC  : ${KEEP_PVC}"
echo "=========================================="

if ! kubectl get namespace "${NS}" >/dev/null 2>&1; then
  echo "Namespace ${NS} does not exist. Nothing to do."
  exit 0
fi

if [[ "${KEEP_PVC}" == "true" ]]; then
  echo ">> Deleting workloads (keeping PVCs)"
  kubectl delete hpa --all -n "${NS}" --ignore-not-found
  kubectl delete deployment --all -n "${NS}" --ignore-not-found
  kubectl delete service --all -n "${NS}" --ignore-not-found
  kubectl delete configmap --all -n "${NS}" --ignore-not-found
  kubectl delete secret --all -n "${NS}" --ignore-not-found
  echo ">> PVCs preserved:"
  kubectl get pvc -n "${NS}"
else
  echo ">> Deleting namespace ${NS} (cascade deletes everything)"
  kubectl delete namespace "${NS}" --wait=true
fi

echo ""
echo "=========================================="
echo " fiapstore stack deleted."
echo "=========================================="
