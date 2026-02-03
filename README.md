# Mobile Content API [![codecov](https://codecov.io/gh/CruGlobal/mobile-content-api/branch/master/graph/badge.svg)](https://app.codecov.io/gh/CruGlobal/mobile-content-api)

Staging push status: [![staging push status](https://github.com/CruGlobal/mobile-content-api/actions/workflows/ruby.yml/badge.svg?event=push&branch=staging)](https://github.com/CruGlobal/mobile-content-api/actions/workflows/ruby.yml)

Master push status: [![master push status](https://github.com/CruGlobal/mobile-content-api/actions/workflows/ruby.yml/badge.svg?event=push&branch=master)](https://github.com/CruGlobal/mobile-content-api/actions/workflows/ruby.yml)

* Ruby version: 2.6.6
* Bundler version: 1.17.3
* Rails version: 5.2.3
* `Draft` --> `Translation.is_published == false`
* You will need to set the following environment variables:
    * MOBILE_CONTENT_API_BUCKET
    * AWS_REGION
    * CROWDIN_API_TOKEN
    * ADOBE_ANALYTICS_REPORT_URL
    * ADOBE_ANALYTICS_COMPANY_ID
    * ADOBE_ANALYTICS_CLIENT_ID
    * ADOBE_ANALYTICS_JWT_TOKEN
    * ADOBE_ANALYTICS_CLIENT_SECRET
    * ADOBE_ANALYTICS_EXCHANGE_JWT_URL
* You will also need to set AWS credentials.


## Local setup

1. `bundle install`
1. `rails db:create db:schema:load`

Use `rspec` to run tests and check if setup is correct.
