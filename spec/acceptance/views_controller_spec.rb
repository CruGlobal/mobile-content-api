# frozen_string_literal: true

require "acceptance_helper"

resource "Views" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }

  post "views/" do
    it "add views" do
      expect do
        do_request data: {type: :view, attributes: {resource_id: 1, quantity: 257}}
      end.to change { Resource.find(1).total_views }.by(257)

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end
