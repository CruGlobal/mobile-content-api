# frozen_string_literal: true

module AuthUtil
  def self.epoch_time_seconds
    Time.new.utc.strftime('%s')
  end
end
