# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :decode_json_api

  def render(**args)
    if args.key? :json
      response.headers['Content-Type'] = 'application/vnd.api+json'
    end

    super
  end

  protected

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

  private

  def decode_json_api
    return if request.headers['REQUEST_METHOD'] == 'GET' ||
              request.headers['Content-Type'] != 'application/vnd.api+json'
    params.merge!(ActiveSupport::JSON.decode(request.body.string))
  end
end
