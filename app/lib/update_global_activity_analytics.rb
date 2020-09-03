# frozen_string_literal: true

# Updates the global activity analytics by fetching data from the endpoint
# and saving it in the `GlobalActivityAnalytics` model. It supposes to do that
# every 24h.
# The threshold is configurable by `GlobalActivityAnalytics::TTL` constant.
class UpdateGlobalActivityAnalytics
  FIELDS = {
    users: {name: "metrics/visitors", options: {sort: "desc"}},
    launches: {name: "metrics/mobilelaunches"},
    gospel_presentations: {name: "metrics/event90"},
    countries: {name: "cm300000683_58877ac221d4771c0d530484"}
  }.freeze

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
    @analytics = GlobalActivityAnalytics.instance
    @analytics_url = ENV.fetch("ADOBE_ANALYTICS_REPORT_URL")
    @company_id = ENV.fetch("ADOBE_ANALYTICS_COMPANY_ID")
    @client_id = ENV.fetch("ADOBE_ANALYTICS_CLIENT_ID")
    @jwt_token = ENV.fetch("ADOBE_ANALYTICS_JWT_TOKEN")
    @client_secret = ENV.fetch("ADOBE_ANALYTICS_CLIENT_SECRET")
    @exchange_jwt_url = ENV.fetch("ADOBE_ANALYTICS_EXCHANGE_JWT_URL")
  end

  def perform
    return if @analytics.actual?

    data = fetch_data
    counters = fetch_counters(data)
    @analytics.update!(counters)
  end

  private

  def fetch_data
    headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer #{access_token}",
      "x-api-key": @client_id,
      "x-proxy-global-company-id": @company_id
    }
    res = Net::HTTP.post(URI(@analytics_url), prepare_query.to_json, headers)
    json_from_http_result(res)
  end

  def access_token
    uri = URI(@exchange_jwt_url)
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/x-www-form-urlencoded"
      req.set_form_data(client_id: @client_id, client_secret: @client_secret, jwt_token: @jwt_token)
      http.request(req)
    }
    json_from_http_result(res)["access_token"]
  end

  def json_from_http_result(res)
    raise res.inspect unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end

  def prepare_query
    today = Time.zone.today
    metrics = FIELDS.map.with_index { |(_, column), index|
      attrs = {
        columnId: index.to_s,
        id: column[:name]
      }
      column.fetch(:options, {}).each { |key, val| attrs[key] = val }
      attrs
    }

    date_range = format(
      DATE_RANGE_TEMPLATE,
      start_year: today.year,
      end_year: (today + 1.year).year
    )

    query = BASE_QUERY.clone
    query["globalFilters"] = [
      {
        "type": "dateRange",
        "dateRange": date_range
      }
    ]
    query["metricContainer"] = {"metrics": metrics}
    query
  end

  def fetch_counters(data)
    Hash[FIELDS.keys.zip(data["summaryData"]["totals"].map(&:to_i))]
  end
end
