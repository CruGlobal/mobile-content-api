# frozen_string_literal: true

require "acceptance_helper"

resource "TranslatedAttributes" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource_id) { Resource.first.id }
  let(:attrs) { {key: "key", "onesky-phrase-id": "phrase", required: true} }
  let(:attrs_underscored) { {key: "key", "onesky_phrase_id": "phrase", required: true} }

  post "/resources/:resource_id/translated-attributes" do
    let(:id) { 100 }

    requires_authorization

    it "create a TranslatedAttribute" do
      expect do
        do_request data: {type: type, attributes: attrs}
      end.to change { TranslatedAttribute.count }.by(1)

      expect(status).to be(204)
      expect(response_body).to be_empty
      expect(TranslatedAttribute.last.attributes.symbolize_keys.slice(:key, :onesky_phrase_id, :required, :resource_id)).to eq(attrs_underscored.merge(resource_id: resource_id))
      expect(response_headers["Location"]).to eq("/resources/#{resource_id}/translated-attributes/#{TranslatedAttribute.last.id}")
    end

    it "defaults required to false" do
      expect do
        do_request data: {type: type, attributes: {key: "key", "onesky-phrase-id": "info.outline"}}
      end.to change { TranslatedAttribute.count }.by(1)

      expect(status).to be(204)
      expect(response_body).to be_empty
      expect(TranslatedAttribute.last.required).to be false
      expect(response_headers["Location"]).to eq("/resources/#{resource_id}/translated-attributes/#{TranslatedAttribute.last.id}")
    end

    it "requires key present" do
      expect do
        do_request data: {type: type, attributes: {"onesky-phrase-id": "phrase"}}
      end.to_not change { TranslatedAttribute.count }

      expect(status).to be(400)
      expect(JSON.parse(response_body)["errors"]).to eq({"code" => "invalid_key"})
    end

    it "requires onesky present" do
      expect do
        do_request data: {type: type, attributes: {key: "key"}}
      end.to_not change { TranslatedAttribute.count }

      expect(status).to be(400)
      expect(JSON.parse(response_body)["errors"]).to eq({"code" => "invalid_onesky_phrase_id"})
    end

    context "translated_attribute already created" do
      let!(:translated_attribute) { FactoryBot.create(:translated_attribute, attrs_underscored.merge(resource_id: resource_id)) }

      it "checks for key already existing" do
        expect do
          do_request data: {type: type, attributes: attrs}
        end.to_not change { TranslatedAttribute.count }

        expect(status).to be(400)
        expect(JSON.parse(response_body)["errors"]).to eq({"code" => "key_already_exists"})
      end
    end
  end

  context "existing translated_attribute" do
    let(:translated_attribute) { FactoryBot.create(:translated_attribute, attrs_underscored.merge(resource_id: resource_id)) }
    let!(:id) { translated_attribute.id }

    put "/resources/:resource_id/translated-attributes/:id" do
      let(:new_attrs) { {key: "updated key", "onesky-phrase-id": "phrase", required: true} }
      let(:new_attrs_underscored) { {key: "updated key", "onesky_phrase_id": "phrase", required: true} }

      requires_authorization

      it "update a Translated Attribute" do
        do_request data: {type: type, attributes: new_attrs}

        expect(status).to be(204)
        expect(response_body).to be_empty
        expect(translated_attribute.reload.attributes.symbolize_keys.slice(:key, :onesky_phrase_id, :required, :resource_id)).to eq(new_attrs_underscored.merge(resource_id: resource_id))
      end

      it "requires key present" do
        expect do
          do_request data: {type: type, attributes: {onesky_phrase_id: "phrase", key: nil}}
        end.to_not change { TranslatedAttribute.count }

        expect(status).to be(400)
        expect(JSON.parse(response_body)["errors"]).to eq({"code" => "invalid_key"})
      end

      it "requires onesky present" do
        expect do
          do_request data: {type: type, attributes: {onesky_phrase_id: nil, key: "key"}}
        end.to_not change { TranslatedAttribute.count }

        expect(status).to be(400)
        expect(JSON.parse(response_body)["errors"]).to eq({"code" => "invalid_onesky_phrase_id"})
      end

      context "translated_attribute already created" do
        let!(:translated_attribute_2) { FactoryBot.create(:translated_attribute, attrs_underscored.merge(key: "updated key", resource_id: resource_id)) }

        it "checks for key already existing" do
          expect do
            do_request data: {type: type, attributes: new_attrs}
          end.to_not change { TranslatedAttribute.count }

          expect(status).to be(400)
          expect(JSON.parse(response_body)["errors"]).to eq({"code" => "key_already_exists"})
        end
      end
    end

    delete "/resources/:resource_id/translated-attributes/:id" do
      requires_authorization

      it "delete a Translated Attribute" do
        expect do
          do_request
        end.to change { TranslatedAttribute.count }.by(-1)

        expect(status).to be(204)
        expect(response_body).to be_empty
        expect(TranslatedAttribute.find_by(id: id)).to be nil
      end
    end
  end
end
