#!/bin/bash

echo "Subindo Users Services..."
docker-compose -f ../usersapi/docker-compose.yaml up -d

echo "Subindo Catalog Services..."
docker-compose -f ../catalogapi/docker-compose.yaml up -d

echo "Subindo Payments Services..."
docker-compose -f ../paymentsapi/docker-compose.yaml up -d

echo "Subindo Notifications Services..."
docker-compose -f ../notificationsapi/docker-compose.yaml up -d


echo "Tudo rodando! 🚀"