# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :decode_json_api

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    render_api_error('Not found.', :not_found)
  end

  rescue_from Error::NotFoundError do |exception|
    render_api_error(exception.message, :not_found)
  end

  rescue_from Error::BadRequestError,
              Error::XmlError,
              ActiveRecord::RecordInvalid,
              Error::MultipleDraftsError,
              Error::TranslationError do |exception|

    render_api_error(exception.message, :bad_request)
  end

  rescue_from Error::TextNotFoundError do |exception|
    render_api_error(exception.message, :conflict)
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

  def render_api_error(message, status)
    render_error(ApiError.new(:id, message), status)
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
