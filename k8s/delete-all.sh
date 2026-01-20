#!/bin/bash

echo "Kubernetes Users Deletando ..."
echo ""

source ../../usersapi/k8s/k8s-delete-all.sh

echo ""
echo "Kubernetes Payments Deletando ..."
echo ""

source ../../paymentsapi/k8s/k8s-delete-all.sh

echo ""
echo "Kubernetes Notifications Deletando ..."
echo ""

source ../../notificationsapi/k8s/k8s-delete-all.sh

echo ""
echo "Kubernetes Catalog Deletando ..."
echo ""

source ../../catalogapi/k8s/k8s-delete-all.sh

echo ""
echo "Kubernetes  Deletado !"
echo ""