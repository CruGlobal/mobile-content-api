class GlobalActivityAnalyticsController < ApplicationController
  def show
    begin
      UpdateGlobalActivityAnalytics.new.perform
    rescue => e
      Rollbar.error(e)
    end
    render json: GlobalActivityAnalytics.instance, status: :ok
  end
end
