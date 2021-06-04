# frozen_string_literal: true

require "rails_helper"

describe View do
  describe "#create" do
    it "must be greater than zero" do
      expect do
        described_class.create!(resource_id: 1, quantity: 0)
      end.to raise_error(Error::BadRequestError, "quantity must be greater than 0")
    end

    it "does not change the resource cache key" do
      expect do
        described_class.create!(resource_id: 1, quantity: 100)
      end.to_not change { Resource.index_cache_key(Resource.all, include_param: nil, fields_param: nil) }
    end
  end
end
