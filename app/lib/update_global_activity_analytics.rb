# frozen_string_literal: true

# Updates the global activity analytics by fetching data from the endpoint
# and saving it in the `GlobalActivityAnalytics` model. It supposes to do that
# every 24h.
# The threshold is configurable by `GlobalActivityAnalytics::TTL` constant.
class UpdateGlobalActivityAnalytics
  # FIELDS = {
  #   users: {name: "metrics/visitors", options: {sort: "desc"}},
  #   launches: {name: "metrics/mobilelaunches"},
  #   gospel_presentations: {name: "metrics/event90"}, # google this is called "EVENT LABEL: Presenting the Gospel"
  #   countries: {name: "cm300000683_58877ac221d4771c0d530484"}
  # }.freeze

  FIELDS = ["users", "sessions", "totalEvents"]

  DATE_RANGE_TEMPLATE = "%{start_year}-01-01T00:00:00.000/%{end_year}-01-01T00:00:00.000"
  BASE_QUERY = {
    "rsid": "vrs_cru1_godtoolsmobileapp",
    "dimension": "variables/geocountry",
    "settings": {
      "countRepeatInstances": true,
      "limit": 400,
      "page": 0,
      "nonesBehavior": "return-nones"
    },
    "statistics": {
      "functions": [
        "col-max",
        "col-min"
      ]
    }
  }

  def initialize
    init_google_instance
  end

  def perform
    # return if @analytics.actual?

    data = fetch_data
    counters = fetch_counters(data)
    return counters
    @analytics.update!(counters)
  end

  private

  def fetch_data
    google_analytics_report
  end

  def fetch_counters(data)
    report = data.reports.first
    headers = report.column_header.metric_header.metric_header_entries.map(&:name)
    results = {}
    headers.each_with_index do |header_name, index|
      results[header_name.sub('ga:', '')] = report.data.rows.first.metrics.first.values[index]
    end
    results
  end

  def init_google_instance
  end

  ### Preliminary Google Analytics Report
  def google_analytics_report
    # Set the date range - this is always required for report requests
    date_range = Google::Apis::AnalyticsreportingV4::DateRange.new(
      start_date: Date.today.beginning_of_year.to_s,
      end_date: (Date.today.beginning_of_year + 1.year).to_s
    )
    # Set the metric
    metrics = FIELDS.map { |field| Google::Apis::AnalyticsreportingV4::Metric.new(
      expression: "ga:#{field}"
    )}

    # Set the dimension
    dimension = Google::Apis::AnalyticsreportingV4::Dimension.new(
      name: "ga:browser"
    )
    # Build up our report request and a add country filter
    report_request = Google::Apis::AnalyticsreportingV4::ReportRequest.new(
      view_id: '234841169',
      sampling_level: 'DEFAULT',
      # filters_expression: "",
      date_ranges: [date_range],
      metrics: metrics # https://github.com/googleapis/google-api-ruby-client/blob/15add33c34031f8d385d6c10a83b646d8c8632de/google-api-client/generated/google/apis/analyticsreporting_v4/classes.rb#L1346
      # dimensions: []
    )
    # Create a new report request
    request = Google::Apis::AnalyticsreportingV4::GetReportsRequest.new(
      { report_requests: [report_request] }
    )
    # Make API call.
    response = $google_client.batch_get_reports(request)
  end
end
