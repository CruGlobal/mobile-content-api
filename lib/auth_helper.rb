require 'digest/md5'

class AuthHelper

  def self.getEpochTimeSeconds
    return Time.new.strftime('%s')
  end

  def self.getDevHash
    return Digest::MD5.hexdigest(getEpochTimeSeconds + ENV['ONESKY_API_SECRET'])
  end

end