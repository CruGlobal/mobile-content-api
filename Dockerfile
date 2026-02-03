# RUBY_VERSION set by build.sh based on .ruby-version file
ARG RUBY_VERSION
FROM public.ecr.aws/docker/library/ruby:${RUBY_VERSION}-alpine

# DataDog logs source
LABEL com.datadoghq.ad.logs='[{"source": "ruby"}]'

# Create web application user to run as non-root
RUN addgroup -g 1000 webapp \
    && adduser -u 1000 -G webapp -s /bin/sh -D webapp \
    && mkdir -p /home/webapp/app
WORKDIR /home/webapp/app

# Upgrade alpine packages (useful for security fixes)
RUN apk upgrade --no-cache

# Install rails/app dependencies
RUN apk --no-cache add libc6-compat git postgresql-libs tzdata jemalloc

ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

# Copy dependency definitions and lock files
COPY Gemfile Gemfile.lock .ruby-version ./

# Install bundler version which created the lock file and configure it
ARG SIDEKIQ_CREDS
RUN gem install bundler -v $(awk '/^BUNDLED WITH/ { getline; print $1; exit }' Gemfile.lock) \
    && bundle config --global gems.contribsys.com $SIDEKIQ_CREDS

# Install build-dependencies, then install gems, subsequently removing build-dependencies
RUN apk --no-cache add --virtual build-deps build-base postgresql-dev yaml-dev \
    && bundle install --jobs 20 --retry 2 \
    && apk del build-deps

# Copy the application
COPY . .

# Environment required to build the application
ARG RAILS_ENV=production
ARG TEST_DB_USER=postgres
ARG TEST_DB_PASSWORD
ARG TEST_DB_HOST=localhost
ARG TEST_DB_PORT=5432
ARG SESSION_REDIS_DB_INDEX=1
ARG SESSION_REDIS_HOST=localhost
ARG SESSION_REDIS_PORT=6379
ARG STORAGE_REDIS_DB_INDEX=1
ARG STORAGE_REDIS_HOST=localhost
ARG STORAGE_REDIS_PORT=6379
ARG MOBILE_CONTENT_API_BUCKET=fake
ARG AWS_REGION=fake
ARG SALESFORCE_AUTH_URI=example.com
ARG SALESFORCE_CLIENT_ID=fake
ARG SALESFORCE_CLIENT_SECRET=fake
ARG SALESFORCE_REST_URI=example.com
ARG SALESFORCE_SFMC_DE_EXTERNAL_KEY=fake
ARG APPLE_CLIENT_ID=org.cru.godtools
ARG APPLE_PRIVATE_KEY=fake
ARG APPLE_KEY_ID=fake
ARG APPLE_TEAM_ID=fake
ARG APPLE_REDIRECT_URI=https://mobile-content-api.cru.org
ARG OKTA_SERVER_URL=example.com
ARG OKTA_SERVER_PATH=fake
ARG OKTA_SERVER_AUDIENCE=fake
ARG FACEBOOK_APP_ID=facebook_app_id
ARG FACEBOOK_APP_SECRET=facebook_app_secret
ARG GOOGLE_APP_ID=fake

# Compile assets and fix permissions
# just like in Actions, we need to copy the fake cred json so that our tests can function
RUN cp spec/fixtures/service_account_cred.json.actions config/secure/service_account_cred.json \
    && RAILS_ENV=test bundle exec rails db:create db:schema:load docs:generate \
    && rm config/secure/service_account_cred.json \
    && chown -R webapp:webapp /home/webapp/

# Define volumes used by ECS to share public html and extra nginx config with nginx container
VOLUME /home/webapp/app/public
VOLUME /home/webapp/app/nginx-conf

# Run container process as non-root user
USER webapp

# Command to start rails
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
