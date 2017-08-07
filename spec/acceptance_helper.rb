# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

RspecApiDocumentation.configure do |config|
  config.format = :json
end

def requires_authorization
  it 'must send a token', document: false do
    blank
  end

  it 'cannot use an expired token', document: false do
    expired
  end
end

private

def blank
  header 'Authorization', nil

  do_request

  expect(status).to be(401)
  expect(JSON.parse(response_body)['data']).to be_nil
end

def expired
  header 'Authorization', expired_token

  do_request

  expect(status).to be(401)
  expect(JSON.parse(response_body)['data']).to be_nil
end

def expired_token
  auth = AuthToken.create!(access_code: AccessCode.find(1))
  auth.update!(expiration: DateTime.now.utc - 25.hours)
  auth.token
end
