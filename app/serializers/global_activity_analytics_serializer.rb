# frozen_string_literal: true

class GlobalActivityAnalyticsSerializer < ActiveModel::Serializer
  type "global_activity_analytics"

  attributes(*GlobalActivityAnalytics::COUNTERS)
end
