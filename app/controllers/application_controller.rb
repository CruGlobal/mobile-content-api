# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :decode_json_api

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    render_error(ApiError.new(:id, 'Not found.'), :not_found)
  end

  # TODO: would be good to do this with all non-runtime errors instead of catching them in controllers
  rescue_from Error::XmlError do |exception|
    render_error(ApiError.new(:id, exception.message), :bad_request)
  end

  def render(**args)
    if args.key? :json
      response.headers['Content-Type'] = 'application/vnd.api+json'
    end

    super
  end

  private

  def data_attrs
    params.require(:data).require(:attributes)
  end

  def authorize!
    authorization = AuthToken.find_by(token: request.headers['Authorization'])
    return unless authorization.nil?

    authorization = AuthToken.new
    authorization.errors.add(:id, 'Unauthorized')
    render_error(authorization, :unauthorized)
  end

  def render_error(json, status)
    render json: json, status: status, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
  end

  def decode_json_api
    return if request.headers['REQUEST_METHOD'] == 'GET' ||
              request.headers['Content-Type'] != 'application/vnd.api+json'
    params.merge!(ActiveSupport::JSON.decode(request.body.string))
  end

  class ApiError
    include ActiveModel::Model

    def initialize(code, message)
      errors.add(code, message)
    end
  end
end
