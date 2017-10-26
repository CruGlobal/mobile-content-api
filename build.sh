#!/bin/bash

docker network create $PROJECT_NAME
docker run --rm --network=$PROJECT_NAME --name=$PROJECT_NAME-postgres -e POSTGRES_PASSWORD=password -d postgres
sleep 2

docker build \
    --network $PROJECT_NAME \
    --build-arg TEST_DB_PASSWORD=password \
    --build-arg TEST_DB_USER=postgres \
    --build-arg TEST_DB_HOST=$PROJECT_NAME-postgres \
    -t 056154071827.dkr.ecr.us-east-1.amazonaws.com/$PROJECT_NAME:$ENVIRONMENT-$BUILD_NUMBER .

docker stop $PROJECT_NAME-postgres
docker network rm $PROJECT_NAME
