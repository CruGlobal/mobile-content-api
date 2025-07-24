# frozen_string_literal: true

require "rails_helper"

describe TranslatedPage do
  it "cannot be created for projects using CrowdIn" do
    result = described_class.create(value: "what a beautiful day", resource_id: 1, language_id: 2)

    expect(result.errors["resource"]).to include("Uses CrowdIn.")
  end
end
