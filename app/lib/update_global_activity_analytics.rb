# frozen_string_literal: true

# Updates the global activity analytics by fetching data from the GA4 Data API
# and saving it in the `GlobalActivityAnalytics` model. It supposes to do that
# every 24h.
# The threshold is configurable by `GlobalActivityAnalytics::TTL` constant.
class UpdateGlobalActivityAnalytics
  SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH = "config/secure/service_account_cred.json"
  GOSPEL_PRESENTATION_EVENT_SUFFIX = "_gospel_presented"

  def initialize
    @analytics = GlobalActivityAnalytics.instance
    init_ga4_client
  end

  def perform
    return if @analytics.actual?

    counters = fetch_all_counters
    @analytics.update!(counters)
  end

  private

  def fetch_all_counters
    users_and_sessions = fetch_users_and_sessions
    gospel_presentations = fetch_gospel_presentations
    countries = fetch_countries_count

    {
      users: users_and_sessions[:users],
      launches: users_and_sessions[:sessions],
      gospel_presentations: gospel_presentations,
      countries: countries
    }
  end

  def fetch_users_and_sessions
    request = Google::Analytics::Data::V1beta::RunReportRequest.new(
      property: "properties/#{property_id}",
      date_ranges: [date_range],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "totalUsers"),
        Google::Analytics::Data::V1beta::Metric.new(name: "sessions")
      ]
    )

    response = @client.run_report(request)
    row = response.rows&.first

    {
      users: row ? row.metric_values[0].value.to_i : 0,
      sessions: row ? row.metric_values[1].value.to_i : 0
    }
  end

  def fetch_gospel_presentations
    request = Google::Analytics::Data::V1beta::RunReportRequest.new(
      property: "properties/#{property_id}",
      date_ranges: [date_range],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "eventCount")
      ],
      dimension_filter: Google::Analytics::Data::V1beta::FilterExpression.new(
        filter: Google::Analytics::Data::V1beta::Filter.new(
          field_name: "eventName",
          string_filter: Google::Analytics::Data::V1beta::Filter::StringFilter.new(
            value: GOSPEL_PRESENTATION_EVENT_SUFFIX,
            match_type: Google::Analytics::Data::V1beta::Filter::StringFilter::MatchType::ENDS_WITH
          )
        )
      )
    )

    response = @client.run_report(request)
    row = response.rows&.first
    row ? row.metric_values[0].value.to_i : 0
  end

  def fetch_countries_count
    request = Google::Analytics::Data::V1beta::RunReportRequest.new(
      property: "properties/#{property_id}",
      date_ranges: [date_range],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "sessions")
      ],
      dimensions: [
        Google::Analytics::Data::V1beta::Dimension.new(name: "country")
      ]
    )

    response = @client.run_report(request)
    response.row_count.to_i
  end

  def init_ga4_client
    @client = Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |config|
      config.credentials = SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH
    end
  end

  def date_range
    Google::Analytics::Data::V1beta::DateRange.new(
      start_date: Date.today.beginning_of_year.to_s,
      end_date: Date.today.to_s
    )
  end

  def property_id
    ENV.fetch("GA4_PROPERTY_ID")
  end
end
