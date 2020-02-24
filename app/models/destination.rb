# frozen_string_literal: true

class Destination < ActiveRecord::Base
  enum service_type: {growth_spaces: "growth_spaces", adobe_campaigns: "adobe_campaigns"}

  validates :url, :service_type, presence: true
  validates :route_id, presence: true, if: :growth_spaces?
  validates :service_name, :adobe_api_key, :adobe_api_secret, presence: true, if: :adobe_campaigns?
end
