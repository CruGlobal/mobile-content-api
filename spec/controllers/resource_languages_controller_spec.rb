# frozen_string_literal: true

require "rails_helper"

describe ResourceLanguagesController, type: :controller do
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }
  let!(:auth_token) { FactoryBot.create(:auth_token) }

  before do
    request.headers["Authorization"] = auth_token.token
  end

  let(:structure) do
    %|<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
        xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
          <pages>
              <page>
                  <content:paragraph>
                      <content:text />
                  </content:paragraph>
                  <content:text />
              </page>
          </pages>
      </tip>|
  end

  context "#update" do
    it "sets the attributes" do
=begin
      {
        "data": {
          "type": "resource-language",
          "id": "1-3",
          "attributes": {
            "attr-enable-tips": true,
            "attr-other-key": null
          }
        }
      }
=end
    end
  end
end
