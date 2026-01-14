#!/bin/bash

echo "Subindo Users Services..."
docker-compose -f ../usersapi/compose.yaml up -d

echo "Subindo Catalog Services..."
docker-compose -f ../catalogapi/compose.yaml up -d

echo "Subindo Payments Services..."
docker-compose -f ../paymentsapi/compose.yaml up -d

echo "Subindo Notifications Services..."
docker-compose -f ../notificationsapi/compose.yaml up -d


echo "Tudo rodando! 🚀"