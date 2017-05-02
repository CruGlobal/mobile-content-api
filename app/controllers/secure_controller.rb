# frozen_string_literal: true

class SecureController < ApplicationController
  before_action :authorize!

  private

  def authorize!
    authorization = AuthToken.find_by(token: request.headers['Authorization'])
    return unless authorization.nil?

    authorization = AuthToken.new
    authorization.errors.add(:id, 'Unauthorized')
    render json: authorization,
           status: :unauthorized,
           adapter: :json_api,
           serializer: ActiveModel::Serializer::ErrorSerializer
  end
end
