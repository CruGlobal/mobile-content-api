# frozen_string_literal: true

require "acceptance_helper"

resource "Drafts" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  get "drafts/" do
    requires_authorization

    it "get all drafts " do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"].size).to be(2)
    end
  end

  get "drafts/:id" do
    let(:id) { "3" }
    let(:page_id) { "1" }
    let(:result) { '{ \"1\": \"phrase\" }' }

    requires_authorization

    before do
      translation = double
      allow(Translation).to receive(:find).with(id).and_return(translation)
      allow(translation).to(receive(:translated_page).with(page_id, false).and_return(result))

      do_request page_id: page_id
    end

    it "get translated page" do
      expect(response_body).to eq(result)
    end

    it "returns OK", document: false do
      expect(status).to be(200)
    end
  end

  get "drafts/:id" do
    let(:id) { "3" }
    let(:tip_id) { "1" }
    let(:result) { '{ \"1\": \"phrase\" }' }

    requires_authorization

    before do
      translation = double
      allow(Translation).to receive(:find).with(id).and_return(translation)
      allow(translation).to(receive(:translated_tip).with(tip_id, false).and_return(result))

      do_request tip_id: tip_id
    end

    it "get translated page" do
      expect(response_body).to eq(result)
    end

    it "returns OK", document: false do
      expect(status).to be(200)
    end
  end

  post "drafts" do
    let(:resource_id) { 1 }
    let(:resource) { instance_double(Resource, id: resource_id) }

    before do
      allow(Resource).to receive(:find).with(resource_id).and_return(resource)
    end

    requires_authorization

    context "one language" do
      let(:id) { 100 }
      let(:language) { 1 }

      before do
        allow(resource).to receive(:create_draft)

        do_request data: {
          type: :translation, attributes: {resource_id: resource_id, language_id: language}
        }
      end

      it "creates a draft" do
        expect(resource).to have_received(:create_draft).with(language)
      end

      it "returns no content", document: false do
        expect(status).to be(204)
      end
    end

    context "multiple languages" do
      let(:id) { 100 }
      let(:language_one) { 1 }
      let(:language_two) { 3 }

      before do
        allow(resource).to receive(:create_draft)

        do_request data: {
          type: :translation, attributes: {resource_id: resource_id, language_ids: [language_one, language_two]}
        }
      end

      it "create two drafts" do
        expect(resource).to have_received(:create_draft).with(language_one)
        expect(resource).to have_received(:create_draft).with(language_two)
      end

      it "returns no content", document: false do
        expect(status).to be(204)
      end
    end
  end

  put "drafts/:id" do
    let(:id) { "3" }
    let(:attrs) { {is_published: true} }

    requires_authorization

    context "all phrases are translated" do
      before do
        translation = Translation.find(3)
        allow(Translation).to receive(:find).with(id).and_return(translation)
        allow(translation).to receive(:update_draft).with(ActionController::Parameters.new(attrs))

        do_request data: {type: :translation, attributes: attrs}
      end

      it "update draft" do
        expect(JSON.parse(response_body)["data"]).not_to be_nil
      end

      it "returns OK", document: false do
        expect(status).to be(200)
      end
    end

    context "all phrases are not translated" do
      it "returns conflict", document: false do
        translation = Translation.find(1)
        allow(translation).to receive(:update_draft).and_raise(Error::TextNotFoundError, "Translated phrase not found.")
        allow(Translation).to receive(:find).with(id).and_return(translation)

        do_request data: {type: :translation, attributes: attrs}

        expect(status).to be(409)
      end
    end
  end

  delete "drafts/:id" do
    let(:id) { 1 }
    let(:translation) { double }

    before do
      allow(Translation).to receive(:find).with(id.to_s).and_return(translation)
    end

    requires_authorization

    it "delete draft" do
      allow(translation).to receive(:destroy!)

      do_request

      expect(status).to be(204)
    end

    it "delete translation" do
      allow(translation).to receive(:destroy!).and_raise(Error::TranslationError, "Cannot delete published drafts.")

      do_request

      expect(status).to be(400)
    end
  end
end
