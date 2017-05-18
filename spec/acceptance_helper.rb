# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

RspecApiDocumentation.configure do |config|
  config.format = :json
end

def requires_authorization
  it 'requires authorization', document: false do
    header 'Authorization', nil

    do_request

    expect(status).to be(401)
    expect(JSON.parse(response_body)['data']).to be_nil
  end
end
