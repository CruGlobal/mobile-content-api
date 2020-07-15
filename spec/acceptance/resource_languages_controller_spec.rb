# frozen_string_literal: true

require "acceptance_helper"

resource "ResourceLanguage" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }
  let(:test_structure) { '<?xml version="1.0" encoding="UTF-8" ?><page> new page </page>' }

  #   get "resource_languages" do
  #     let(:attrs) { {filename: "test.xml", structure: test_structure, resource_id: 2, position: 1} }
  #
  #     before do
  #       allow(Page).to(receive(:create!).with(ActionController::Parameters.new(attrs).permit!)
  #                          .and_return(Page.new(id: 12_345)))
  #     end
  #
  #     requires_authorization
  #
  #     before do
  #       allow(Page).to(receive(:create!).with(ActionController::Parameters.new(attrs).permit!)
  #                        .and_return(Page.new(id: 12_345)))
  #     end
  #
  #     it "create page" do
  #       do_request data: {type: :page, attributes: attrs}
  #
  #       expect(status).to eq(201)
  #       expect(JSON.parse(response_body)["data"]).not_to be_nil
  #     end
  #
  #     it "sets location header", document: false do
  #       do_request data: {type: :page, attributes: attrs}
  #
  #       expect(response_headers["Location"]).to eq("pages/12345")
  #     end
  #   end
  # TODO

  put "resources/:resource_id/languages/:id" do
    let(:resource) { Resource.first }
    let(:language) { Language.first }
    let(:data) do
      {
        "type": "resource-language",
        "id": "#{resource.id}-#{language.id}",
        "attributes": {
          "attr-enable-tips": true,
          "attr-other-key": nil,
        },
      }
    end
    let(:id) { 1 }
    let(:resource_id) { 1 }
    let(:attrs) { {structure: test_structure} }
    let(:language) { Language.first }
    let(:attr) { {test: 5} }

    #     before do
    #       p = Page.find(1)
    #       allow(Page).to receive(:find).and_return(p)
    #       allow(p).to receive(:update!).with(ActionController::Parameters.new(attrs).permit!)
    #     end

    requires_authorization

    it "update resource language" do
      do_request data: data
      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      att = Attribute.find_by(resource: resource, language: language, key: "enable_tips")
      expect(att).to_not be_nil
      expect(att.value).to eq("t")
      att = Attribute.find_by(resource: resource, language: language, key: "other_key")
      expect(att).to be_nil
    end
  end
end
