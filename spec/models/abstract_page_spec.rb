# frozen_string_literal: true

require "rails_helper"

describe AbstractPage do
  it "validates XML strictly" do
    result = Page.create(filename: "test.xml", resource_id: 1, structure: "<open>", position: 1)

    expect(result.errors["structure"]).to include("1:7: FATAL: Premature end of data in tag open line 1")
  end

  it "validates XML on create" do
    result = Page.create(filename: "test.xml", resource_id: 1, structure: "<page />", position: 1)

    expect(result.errors["structure"]).to include("1:0: ERROR: Element 'page': No matching global declaration available for the validation root.")
  end

  it "validates XML on update" do
    custom_page = CustomPage.find(1)

    custom_page.update(structure: "<page />")

    expect(custom_page.errors["structure"]).to include("1:0: ERROR: Element 'page': No matching global declaration available for the validation root.")
  end
end
