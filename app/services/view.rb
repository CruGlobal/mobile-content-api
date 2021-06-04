# frozen_string_literal: true

class View
  def self.create!(resource_id:, quantity:)
    unless quantity.is_a?(Numeric) && quantity.positive?
      raise Error::BadRequestError, "quantity must be greater than 0"
    end
    Resource.find(resource_id).increment!(:total_views, quantity)
  end
end
