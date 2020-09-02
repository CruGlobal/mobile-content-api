# Mobile Content API [![Build Status](https://travis-ci.org/CruGlobal/mobile-content-api.svg?branch=master)](https://travis-ci.org/CruGlobal/mobile-content-api) [![codecov](https://codecov.io/gh/CruGlobal/mobile-content-api/branch/master/graph/badge.svg)](https://codecov.io/gh/CruGlobal/mobile-content-api)

* Ruby version: 2.6.6
* Bundler version: 1.17.3
* Rails version: 5.2.3
* `Draft` --> `Translation.is_published == false`
* You will need to set the following environment variables:
    * MOBILE_CONTENT_API_BUCKET
    * AWS_REGION
    * ONESKY_API_KEY
    * ONESKY_API_SECRET
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
