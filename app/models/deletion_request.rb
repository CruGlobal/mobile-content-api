class DeletionRequest < ApplicationRecord
  validates_presence_of :uid, :provider, :pid

  # there can only be one entry with given provider + uid
  validates_uniqueness_of :uid, scope: :provider

  before_validation :set_pid

  def run
    associated_user&.destroy!
  end

  def deleted?
    associated_user.nil?
  end

  def self.from_signed_fb(req)
    data = DeletionRequest.parse_fb_request(req)
    return unless data
    DeletionRequest.create(provider: "facebook", uid: data["user_id"])
  end

  def self.parse_fb_request(req)
    encoded, payload = req.split(".", 2)
    decoded = Base64.urlsafe_decode64(encoded)
    data = JSON.parse(Base64.urlsafe_decode64(payload))

    # we need to verify the digest is the same
    exp = OpenSSL::HMAC.digest("SHA256", ENV["FACEBOOK_APP_SECRET"], payload)
    raise FailedAuthentication, "FB deletion callback called with invalid data" if decoded != exp

    data
  end

  private

  def associated_user
    # more providers will be added
    case provider
    when "facebook"
      User.find_by(facebook_user_id: uid)
    end
  end

  def set_pid
    if pid.blank?
      self.pid = random_pid
    end
  end

  def random_pid
    SecureRandom.hex(4)
  end

  class FailedAuthentication < StandardError
  end
end
