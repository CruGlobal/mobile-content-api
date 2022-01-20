# frozen_string_literal: true

require "rails_helper"

describe UserCounter do
  let(:name_invalid) { "invalid:name" }

  let(:user) { FactoryBot.create(:user) }

  it "cannot use invalid counter name" do
    result = described_class.create(user: user, counter_name: name_invalid)

    expect(result.errors["counter_name"]).to include("has invalid characters")
  end
end
