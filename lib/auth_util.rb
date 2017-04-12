# frozen_string_literal: true
require 'digest/md5'

module AuthUtil
  def self.epoch_time_seconds
    Time.new.utc.strftime('%s')
  end

  def self.dev_hash
    Digest::MD5.hexdigest(epoch_time_seconds + ENV['ONESKY_API_SECRET'])
  end
end
