# frozen_string_literal: true

class Destination < ActiveRecord::Base
  enum service_type: {growth_spaces: "growth_spaces", adobe_campaigns: "adobe_campaigns"}

  validates :url, :service_type, presence: true
end
