# frozen_string_literal: true

require "acceptance_helper"

resource "Systems" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }

  get "systems" do
    it "get all systems" do
      do_request

      expect(status).to be(200)
    end
  end

  get "systems/:id" do
    let(:id) { 1 }

    it "get system" do
      do_request

      expect(status).to be(200)
    end
  end
end
