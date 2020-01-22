# frozen_string_literal: true

# Keeps data that comes from Adobe Analytics for
# the global activity analytics. The data is exposed to mobile apps
# via an API endpoint.
# It's a singleton model, so having many instances is not possible.
# Use `GlobalActivityAnalytics.instance` method to get the correct instance.
class GlobalActivityAnalytics < ApplicationRecord
  TTL = 24.hours
  COUNTERS = %i[users countries launches gospel_presentations].freeze

  def self.instance
    first_or_create!(updated_at: 1.second.before(TTL.ago))
  end

  def actual?
    updated_at > TTL.ago
  end
end
