# frozen_string_literal: true
require 'digest/md5'

# this module only has one method so we can easily ignore the Brakeman check on MD5
module HashUtil
  def self.dev_hash
    Digest::MD5.hexdigest(AuthUtil.epoch_time_seconds + ENV['ONESKY_API_SECRET'])
  end
end
