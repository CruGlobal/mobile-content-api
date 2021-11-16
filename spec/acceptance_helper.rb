# frozen_string_literal: true

require "rails_helper"
require "rspec_api_documentation"
require "rspec_api_documentation/dsl"

RspecApiDocumentation.configure do |config|
  config.format = :json
end

RSpec.configure do |config|
  config.extend(Module.new {
    def requires_authorization
      before do
        header "Authorization", :authorization
      end

      after do
        header "Authorization", nil
      end

      it "must send a token", document: false do
        blank
      end

      it "cannot use an expired token", document: false do
        expired
      end
    end

    def requires_okta_authorization
      before do
        header "Authorization", AuthToken.encode({user_id: user.id})
      end

      after do
        header "Authorization", nil
      end

      it "returns unauthorized if no user" do
        no_user
      end
    end
  })
  config.include(Module.new {
    def type
      example.metadata[:resource_name].singularize.underscore.tr("_", "-")
    end

    def blank
      header "Authorization", nil

      do_request

      expect(status).to be(401)
      expect(JSON.parse(response_body)["data"]).to be nil
    end

    def expired
      header "Authorization", expired_token

      do_request

      expect(status).to be(401)
      expect(JSON.parse(response_body)["data"]).to be nil
    end

    def expired_token
      AuthToken.encode(exp: 1.hour.ago.to_i)
    end

    def no_user
      header "Authorization", AuthToken.encode({})

      do_request

      expect(status).to be(401)
      expect(JSON.parse(response_body)["data"]).to be nil
    end
  })
end
