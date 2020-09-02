# frozen_string_literal: true

require "acceptance_helper"

resource "TranslatedAttributes" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  post "translated_attributes" do
    let(:attrs) do
      {attribute_id: 2, translation_id: 2, value: "translated attr"}
    end
    let(:id) { 100 }

    before do
      allow(TranslatedAttribute).to receive(:create!).and_return(TranslatedAttribute.new(id: id))
    end

    requires_authorization

    it "create a Translated Attribute" do
      do_request data: {type: type, attributes: attrs}

      expect(status).to be(204)
      expect(response_body).to be_empty
    end

    it "sets location header", document: false do
      do_request data: {type: type, attributes: attrs}

      expect(response_headers["Location"]).to eq("translated_attributes/#{id}")
    end
  end

  put "translated_attributes/:id" do
    let(:id) { 1 }
    let(:attrs) do
      {attribute_id: 2, translation_id: 3, value: "updated translation"}
    end

    requires_authorization

    it "update a Translated Attribute" do
      attribute = instance_double(TranslatedAttribute, update!: nil)
      allow(TranslatedAttribute).to receive(:find).and_return(attribute)

      do_request data: {type: type, attributes: attrs}

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  delete "translated_attributes/:id" do
    let(:id) { 1 }

    requires_authorization

    it "delete a Translated Attribute" do
      attribute = instance_double(TranslatedAttribute, destroy!: nil)
      allow(TranslatedAttribute).to receive(:find).and_return(attribute)

      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end
