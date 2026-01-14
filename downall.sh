#!/bin/bash

echo "Shut Down Users Services..."

cd ..
cd ./usersapi/
docker-compose down -v
cd ..

echo "Shut Down Catalog Services..."

cd ./catalogapi/
docker-compose down -v
cd ..


echo "Shut Down Payments Services..."


cd ./paymentsapi/
docker-compose down -v
cd ..


echo "Shut Down Notifications Services..."

cd ./notificationsapi/
docker-compose down -v
cd ..
cd ./orchestration/