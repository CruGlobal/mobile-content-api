# frozen_string_literal: true

require "acceptance_helper"

resource "Languages" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  get "languages" do
    it "get all languages" do
      do_request

      expect(status).to be(200)
    end

    it "sorts by name ascending", document: false do
      do_request

      expect(JSON.parse(response_body)["data"][0]["id"]).to eq("4")
    end
  end

  get "languages/:id" do
    let(:id) { 2 }

    it "get language" do
      do_request

      expect(status).to be(200)
    end
  end

  post "languages" do
    requires_authorization

    it "create a language" do
      do_request data: {type: :language, attributes: {name: "Elvish", code: "ev"}}

      expect(status).to be(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(JSON.parse(response_body)["data"]["attributes"]["force-language-name"]).to be false
    end

    it "sets force language name" do
      do_request data: {type: :language, attributes: {name: "Elvish", code: "ev", :"force-language-name" => true}}

      expect(status).to be(201)
      expect(JSON.parse(response_body)["data"]["attributes"]["force-language-name"]).to be true
    end

    it "sets location header", document: false do
      do_request data: {type: :language, attributes: {name: "Elvish", code: "ev"}}

      expect(response_headers["Location"]).to match(%r{languages/\d+})
    end

    it "cannot duplicate code", document: false do
      code = "en"

      do_request data: {type: type, attributes: {name: "another English", code: code}}

      expect(status).to be(400)
      expect(JSON.parse(response_body)["errors"][0]["detail"]).to eq("Code #{code} already exists.")
    end

    it "defaults direction to ltr", document: false do
      do_request data: {type: type, attributes: {name: "Elvish", code: "ev"}}

      expect(JSON.parse(response_body)["data"]["attributes"]["direction"]).to eq("ltr")
    end

    it "honors direction when set to rtl", document: false do
      do_request data: {type: type, attributes: {name: "Elvish", code: "ev", direction: "rtl"}}

      expect(JSON.parse(response_body)["data"]["attributes"]["direction"]).to eq("rtl")
    end

    it "fails on invalid direction value", document: false do
      do_request data: {type: type, attributes: {name: "Elvish", code: "ev", direction: "bogus"}}

      error = "Validation failed: Bogus Invalid direction bogus. Valid values for direction are 'ltr' and 'rtl'"
      expect(status).to be(400)
      expect(JSON.parse(response_body)["errors"][0]["detail"]).to eq(error)
    end
  end

  delete "languages/:id" do
    let(:id) { 3 }

    before do
      header "Authorization", :authorization
    end

    requires_authorization

    it "delete a language" do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end
