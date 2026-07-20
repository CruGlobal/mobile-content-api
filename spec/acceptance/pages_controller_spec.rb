# frozen_string_literal: true

require "acceptance_helper"

resource "Pages" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:test_structure) { '<?xml version="1.0" encoding="UTF-8" ?><page> new page </page>' }

  post "pages" do
    let(:attrs) { {filename: "test.xml", structure: test_structure, resource_id: 2, position: 1} }

    before do
      allow(Page).to(receive(:create!).with(ActionController::Parameters.new(attrs).permit!)
                         .and_return(Page.new(id: 12_345)))
    end

    requires_authorization

    before do
      allow(Page).to(receive(:create!).with(ActionController::Parameters.new(attrs).permit!)
                       .and_return(Page.new(id: 12_345)))
    end

    it "create page" do
      do_request data: {type: :page, attributes: attrs}

      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end

    it "sets location header", document: false do
      do_request data: {type: :page, attributes: attrs}

      expect(response_headers["Location"]).to eq("pages/12345")
    end
  end

  put "pages/:id" do
    let(:id) { 1 }
    let(:attrs) { {structure: test_structure} }

    before do
      p = Page.find(1)
      allow(Page).to receive(:find).and_return(p)
      allow(p).to receive(:update!).with(ActionController::Parameters.new(attrs).permit!)
    end

    requires_authorization

    it "edit page" do
      do_request data: {type: :page, attributes: attrs}

      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end
  end

  put "pages/:id" do
    let(:id) { 1 }

    requires_authorization

    it "updates the filename" do
      do_request data: {type: :page, attributes: {filename: "renamed.xml"}}

      expect(status).to eq(200)
      expect(Page.find(1).filename).to eq("renamed.xml")
    end

    it "updates the position" do
      do_request data: {type: :page, attributes: {position: 7}}

      expect(status).to eq(200)
      expect(Page.find(1).position).to eq(7)
    end

    it "rejects a filename already used by another page of the resource" do
      other = Page.find(1).resource.pages.where.not(id: 1).first

      do_request data: {type: :page, attributes: {filename: other.filename}}

      expect(status).to eq(400)
      expect(Page.find(1).filename).not_to eq(other.filename)
    end
  end

  post "resources/:resource_id/pages/reorder" do
    let(:resource_id) { 1 }
    let(:ordered_ids) { Resource.find(1).pages.order(:position).pluck(:id) }

    requires_authorization

    it "reorders the resource's pages" do
      reversed_ids = ordered_ids.reverse

      do_request data: {type: :page, attributes: {page_ids: reversed_ids}}

      expect(status).to eq(200)
      expect(Resource.find(1).pages.order(:position).pluck(:id)).to eq(reversed_ids)
      expect(Resource.find(1).pages.order(:position).pluck(:position)).to eq([0, 1])

      body_pages = JSON.parse(response_body)["data"]
      expect(body_pages.map { |page| page["attributes"]["position"] }).to eq([0, 1])
    end

    it "rejects page ids that don't match the resource's pages" do
      do_request data: {type: :page, attributes: {page_ids: [ordered_ids.first]}}

      expect(status).to eq(400)
    end
  end
end
