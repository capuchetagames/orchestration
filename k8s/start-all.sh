#!/bin/bash

echo "Kubernetes Users"
echo ""

source ../../usersapi/k8s/k8s-start-all-dev.sh

echo ""
echo "Kubernetes Payments"
echo ""

source ../../paymentsapi/k8s/k8s-start-all-dev.sh

echo ""
echo "Kubernetes Notifications"
echo ""

source ../../notificationsapi/k8s/k8s-start-all-dev.sh

echo ""
echo "Kubernetes Catalog"
echo ""

source ../../catalogapi/k8s/k8s-start-all-dev.sh

echo ""
echo "Kubernetes Rodando! 🚀"
echo ""