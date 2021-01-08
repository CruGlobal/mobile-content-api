FROM 056154071827.dkr.ecr.us-east-1.amazonaws.com/base-image-ruby-version-arg:2.6
MAINTAINER cru.org <wmd@cru.org>

ARG RAILS_ENV=production

ARG DD_API_KEY
RUN DD_AGENT_MAJOR_VERSION=7 DD_INSTALL_ONLY=true DD_API_KEY=$DD_API_KEY bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"

# Config for logging to datadog
COPY docker/datadog-agent /etc/datadog-agent
COPY docker/supervisord-datadog.conf /etc/supervisor/conf.d/supervisord-datadog.conf
COPY docker/docker-entrypoint.sh /

COPY Gemfile Gemfile.lock ./

RUN bundle config gems.contribsys.com $SIDEKIQ_CREDS
RUN bundle install --jobs 20 --retry 5 --path vendor
RUN bundle binstub puma rake

COPY . ./

ARG TEST_DB_USER=postgres
ARG TEST_DB_PASSWORD=
ARG TEST_DB_HOST=localhost
ARG TEST_DB_PORT=5432

# just like in travis, we need to copy the fake cred json so that our tests can function
RUN cp spec/fixtures/service_account_cred.json.travis config/secure/service_account_cred.json
RUN bundle exec rails db:create db:schema:load docs:generate RAILS_ENV=test
RUN rm config/secure/service_account_cred.json
RUN bundle exec rails assets:clobber assets:precompile RAILS_ENV=test

## Run this last to make sure permissions are all correct
RUN mkdir -p /home/app/webapp/tmp \
             /home/app/webapp/db \
             /home/app/webapp/log \
             /home/app/webapp/public/uploads \
             /home/app/webapp/config/secure \
             /home/app/webapp/pages && \
    chmod -R ugo+rw /home/app/webapp/tmp \
                    /home/app/webapp/db \
                    /home/app/webapp/log \
                    /home/app/webapp/public/uploads \
                    /home/app/webapp/config/secure \
                    /home/app/webapp/pages

COPY cable.conf /usr/local/openresty/nginx/conf/location/cable.conf

CMD "/docker-entrypoint.sh"
