# frozen_string_literal: true

require "rails_helper"

describe View do
  it "must be greater than zero" do
    expect do
      described_class.create!(resource_id: 1, quantity: 0)
    end.to raise_error(Error::BadRequestError, "quantity must be greater than 0")
  end
end
