# frozen_string_literal: true
require 'digest/md5'

class AuthHelper
  def self.epoch_time_seconds
    Time.new.strftime('%s')
  end

  def self.dev_hash
    Digest.MD5.hexdigest(epoch_time_seconds + ENV['ONESKY_API_SECRET'])
  end
end
