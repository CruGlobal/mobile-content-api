# frozen_string_literal: true

class Destination < ActiveRecord::Base
  enum service_type: {growth_spaces: "growth_spaces", adobe_campaigns: "adobe_campaigns", salesforce: "salesforce"}

  validates :url, :service_type, :access_key_id, :access_key_secret, presence: true
  validates :route_id, presence: true, if: :growth_spaces?
  validates :service_name, presence: true, if: ->(destination) { destination.adobe_campaigns? || destination.salesforce? }
end
