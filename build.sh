#!/bin/bash

docker run --rm --network=$DOCKER_NETWORK --name=$PROJECT_NAME-postgres -e POSTGRES_PASSWORD=password -d postgres
sleep 5

PG_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PROJECT_NAME-postgres)

docker buildx build $DOCKER_ARGS \
    --build-arg TEST_DB_PASSWORD=password \
    --build-arg TEST_DB_USER=postgres \
    --build-arg TEST_DB_HOST=$PG_IP \
    --build-arg RUBY_VERSION=$(cat .ruby-version) \
    .
rc=$?

docker stop $PROJECT_NAME-postgres

if [ $rc -ne 0 ]; then
  echo -e "Docker build failed"
  exit $rc
fi

