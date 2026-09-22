require "google/analytics/data/v1beta"

module TestHelpers
  module_function def stub_request_to_analytics(rspec_context, analytics_status: 200, access_token_status: 200)
    rspec_context.instance_eval do
      ENV["GA4_PROPERTY_ID"] = "234841169"

      # Load GA4 fixture data
      analytics_data = JSON.parse(File.read(Rails.root.join("spec", "fixtures", "ga4_analytics_stub.json")))
      countries_data = JSON.parse(File.read(Rails.root.join("spec", "fixtures", "ga4_countries_stub.json")))
      gospel_data = JSON.parse(File.read(Rails.root.join("spec", "fixtures", "ga4_gospel_presentations_stub.json")))

      # Build mock responses
      analytics_response = TestHelpers.build_ga4_response(analytics_data)
      countries_response = TestHelpers.build_ga4_response(countries_data)
      gospel_response = TestHelpers.build_ga4_response(gospel_data)

      # Mock the GA4 client
      mock_client = instance_double(Google::Analytics::Data::V1beta::AnalyticsData::Client)

      if analytics_status == 200 && access_token_status == 200
        allow(mock_client).to receive(:run_report).and_return(
          analytics_response,
          gospel_response,
          countries_response
        )
      else
        allow(mock_client).to receive(:run_report).and_raise(Google::Cloud::InvalidArgumentError.new("Invalid request"))
      end

      allow(Google::Analytics::Data::V1beta::AnalyticsData::Client).to receive(:new).and_return(mock_client)
    end
  end

  module_function def build_ga4_response(data)
    rows = (data["rows"] || []).map do |row|
      metric_values = (row["metricValues"] || []).map do |mv|
        Google::Analytics::Data::V1beta::MetricValue.new(value: mv["value"])
      end
      dimension_values = (row["dimensionValues"] || []).map do |dv|
        Google::Analytics::Data::V1beta::DimensionValue.new(value: dv["value"])
      end
      Google::Analytics::Data::V1beta::Row.new(
        metric_values: metric_values,
        dimension_values: dimension_values
      )
    end

    Google::Analytics::Data::V1beta::RunReportResponse.new(
      rows: rows,
      row_count: data["rowCount"] || rows.size
    )
  end
end
