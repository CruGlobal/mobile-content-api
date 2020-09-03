# frozen_string_literal: true

require "acceptance_helper"

resource "CustomManifests" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:structure) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:article="https://mobile-content-api.cru.org/xmlns/article"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
    <title><content:text i18n-id="name">About God</content:text></title>
</manifest>'
  end

  let(:access_code) { AccessCode.find(1) }
  let(:authorization) do
    AuthToken.create!(access_code: access_code).token
  end

  let(:resource) { Resource.first }
  let(:language) { Language.first }

  let(:empty_structure) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
</manifest>'
  end

  let(:a_custom_manifest) do
    resource.custom_manifests.where(language: language).first ||
      resource.custom_manifests.create!(language: language, structure: empty_structure)
  end

  post "custom_manifests/" do
    requires_authorization

    it "creates a custom manifest" do
      attrs = {language_id: language.id, resource_id: resource.id, structure: structure}
      do_request data: {type: type, attributes: attrs}

      expect(status).to be(201)

      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(response_headers["Location"]).to match(%r{custom_manifests/\d+})
    end

    it "updates a custom manifest" do
      a_custom_manifest
      attrs = {language_id: language.id, resource_id: resource.id, structure: structure}
      do_request data: {attributes: attrs}

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"]).not_to be nil
    end
  end

  put "custom_manifests/:id" do
    let(:id) { a_custom_manifest.id }

    requires_authorization

    it "updates a custom manifest" do
      attrs = {structure: structure}
      do_request data: {type: type, attributes: attrs}

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"]).not_to be nil
    end
  end

  delete "custom_manifests/:id" do
    let(:id) { a_custom_manifest.id }

    requires_authorization

    it "delete a custom manifest" do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  get "custom_manifests/:id" do
    let(:id) { a_custom_manifest.id }

    it "retrieves a custom manifest" do
      do_request

      expect(status).to be(200)
      data = JSON.parse(response_body)["data"]
      expect(data["id"].to_i).to eql id
      expect(data["type"]).to eql "custom-manifest"
    end
  end
end
