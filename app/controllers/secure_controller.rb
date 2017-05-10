# frozen_string_literal: true

class SecureController < ApplicationController
  before_action :authorize!

  private

  def authorize!
    token = AuthToken.find_by(token: request.headers['Authorization'])
    return unless token.nil? || expired(token)

    token = AuthToken.new
    token.errors.add(:id, 'Unauthorized')
    render_error(token, :unauthorized)
  end

  def expired(token)
    token.expiration < DateTime.now.utc
  end
end
