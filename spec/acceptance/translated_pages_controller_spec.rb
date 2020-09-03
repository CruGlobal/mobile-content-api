# frozen_string_literal: true

require "acceptance_helper"

resource "TranslatedPages" do
  let(:authorization) { AuthToken.generic_token }
  let(:article) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<article xmlns="https://mobile-content-api.cru.org/xmlns/article">
</article>'
  end
  let(:data) { {data: {type: "translated-page", attributes: {value: article, resource_id: 3, language_id: 2}}} }

  post "translated_pages/" do
    requires_authorization

    it "create an Translated Page" do
      do_request data

      expect(status).to be(201)
      expect(response_body).not_to be_nil
    end

    it "sets location header", document: false do
      do_request data

      expect(response_headers["Location"]).to match(%r{translated_pages/\d+})
    end
  end

  put "translated_pages/:id" do
    let(:id) { 1 }

    requires_authorization

    it "update an Translated Pages" do
      do_request data

      expect(status).to be(201)
      expect(response_body).not_to be_nil
    end
  end

  delete "translated_pages/:id" do
    let(:id) { 1 }

    requires_authorization

    it "delete an Translated Page" do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end
