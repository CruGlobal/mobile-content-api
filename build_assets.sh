#!/usr/bin/env bash

# Build Documentation
pg_pass=`openssl rand -base64 16`
docker run --name pg-mobile-content-api -e POSTGRES_PASSWORD=${pg_pass} -d -p 32769:5432 postgres &&
sleep 10 # Give DB container time to spin up

bundle exec rake db:create db:setup docs:generate \
  RAILS_ENV=test \
  TEST_DB_USER=postgres \
  TEST_DB_PASSWORD=${pg_pass} \
  TEST_DB_HOST=127.0.0.1 \
  TEST_DB_PORT=32769
rc=$?

docker stop pg-mobile-content-api
docker rm pg-mobile-content-api

exit $rc
