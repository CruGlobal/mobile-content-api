# frozen_string_literal: true

require "rails_helper"

describe ResourceType do
  it "must have a valid DTD file" do
    name = "test resource type"

    result = described_class.create(name: name, dtd_file: "blah.xsd")

    expect(result.errors["dtd-file"]).to include("Does not exist.")
  end
end
