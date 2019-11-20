# Mobile Content API [![Build Status](https://travis-ci.org/CruGlobal/mobile-content-api.svg?branch=master)](https://travis-ci.org/CruGlobal/mobile-content-api) [![codecov](https://codecov.io/gh/CruGlobal/mobile-content-api/branch/master/graph/badge.svg)](https://codecov.io/gh/CruGlobal/mobile-content-api)

* Ruby version: 2.3.4
* Bundler version: 1.16.1
* Rails version: 5.0.2
* `Draft` --> `Translation.is_published == false`
* You will need to set the following environment variables:
    * MOBILE_CONTENT_API_BUCKET
    * AWS_REGION
    * ONESKY_API_KEY
    * ONESKY_API_SECRET
* You will also need to set AWS credentials.


## Local setup

1. `bundle install`
1. `rake db:create`
1. `rake db:schema:load`
1. `RAILS_ENV=test rake db:seed`

Use `rspec` to run tests and check if setup is correct.
