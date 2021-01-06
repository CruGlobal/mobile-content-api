# frozen_string_literal: true

# Updates the global activity analytics by fetching data from the endpoint
# and saving it in the `GlobalActivityAnalytics` model. It supposes to do that
# every 24h.
# The threshold is configurable by `GlobalActivityAnalytics::TTL` constant.
class UpdateGlobalActivityAnalytics
  SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH = "config/secure/service_account_cred.json"

  def initialize
    init_google_instance
    @analytics = GlobalActivityAnalytics.instance
  end

  def perform
    return if @analytics.actual?

    data = google_analytics_report
    counters = fetch_counters(data)
    @analytics.update!(counters)
  end

  private

  def fetch_counters(data)
    results = {}
    data.reports.each do |report|
      headers = report.column_header.metric_header.metric_header_entries.map(&:name)
      first_row = report.data.rows&.first
      headers.each_with_index do |header_name, index|
        if header_name == "countries"
          results[header_name] = report.data.rows.count
        else
          results[header_name.sub("ga:", "")] = first_row ? first_row.metrics.first.values[index] : 0
        end
      end
    end
    results
  end

  def init_google_instance
    service = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new

    # Create service account credentials
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      # this file is downloaded from s3 in production via config/initializers/sync_secure_google_creds.rb
      json_key_io: File.open(SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH),
      scope: "https://www.googleapis.com/auth/analytics.readonly"
    )

    # Authorize with our readonly credentials
    service.authorization = credentials

    @google_client = service
  end

  def date_range
    Google::Apis::AnalyticsreportingV4::DateRange.new(
      start_date: Date.today.beginning_of_year.to_s,
      end_date: (Date.today.beginning_of_year + 1.year).to_s
    )
  end

  def sessions_and_users_request
    metrics = [Google::Apis::AnalyticsreportingV4::Metric.new(
      expression: "ga:users"
    ),

      Google::Apis::AnalyticsreportingV4::Metric.new(
        expression: "ga:sessions",
        alias: "launches"
      )]

    Google::Apis::AnalyticsreportingV4::ReportRequest.new(
      view_id: ENV.fetch("GOOGLE_ANALYTICS_VIEW_ID"),
      sampling_level: "DEFAULT",
      date_ranges: [date_range],
      metrics: metrics,
      dimensions: []
    )
  end

  def gospel_presentations_request
    metrics = [Google::Apis::AnalyticsreportingV4::Metric.new(
      expression: "ga:totalEvents",
      alias: "gospel_presentations"
    )]

    Google::Apis::AnalyticsreportingV4::ReportRequest.new(
      view_id: ENV.fetch("GOOGLE_ANALYTICS_VIEW_ID"),
      sampling_level: "DEFAULT",
      filters_expression: "ga:eventLabel==presenting the gospel",
      date_ranges: [date_range],
      metrics: metrics,
      dimensions: []
    )
  end

  def countries_request
    metrics = [Google::Apis::AnalyticsreportingV4::Metric.new(
      expression: "ga:sessions",
      alias: "countries"
    )]

    countries_dimesion = Google::Apis::AnalyticsreportingV4::Dimension.new(
      name: "ga:country"
    )

    Google::Apis::AnalyticsreportingV4::ReportRequest.new(
      view_id: ENV.fetch("GOOGLE_ANALYTICS_VIEW_ID"),
      sampling_level: "DEFAULT",
      date_ranges: [date_range],
      metrics: metrics,
      dimensions: [countries_dimesion]
    )
  end

  def google_analytics_report
    # Create a new report request
    request = Google::Apis::AnalyticsreportingV4::GetReportsRequest.new(
      report_requests: [sessions_and_users_request, gospel_presentations_request, countries_request]
    )
    # Make API call.
    @google_client.batch_get_reports(request)
  end
end
