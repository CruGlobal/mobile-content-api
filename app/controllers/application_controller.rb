# frozen_string_literal: true

class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :decode_json_api

  rescue_from ActiveRecord::RecordNotFound, Error::NotFoundError do |exception|
    render_api_error(exception, :not_found)
  end

  rescue_from Error::BadRequestError,
    RestClient::Exception,
    Error::XmlError,
    ActiveRecord::RecordInvalid,
    Error::MultipleDraftsError,
    Error::TranslationError do |exception|
    if Rails.env.development? || Rails.env.test?
      logger.error exception.message
      exception.backtrace.each { |line| logger.error line }
    end
    render_api_error(exception, :bad_request)
  end

  rescue_from Error::TextNotFoundError do |exception|
    render_api_error(exception, :conflict)
  end

  def render(**args)
    response.headers["Content-Type"] = "application/vnd.api+json" if args.key?(:json)

    super
  end

  private

  def data_attrs
    params.require(:data).require(:attributes)
  end

  def permit_params(*params)
    data_attrs.permit(params)
  end

  def authorize!
    authorization = AuthToken.decode(request.headers["Authorization"])

    if authorization
      user_id = authorization.first.with_indifferent_access[:user_id]
      return unless user_id # requested is authorized if using generic JWT
      return if User.find_by(id: user_id)&.admin
    end

    render_unauthorized
  end

  def render_unauthorized
    authorization = AccessCode.new
    authorization.errors.add(:id, "Unauthorized")
    render_error(authorization, :unauthorized)
  end

  def render_api_error(exception, status)
    render_error(ApiError.new(:id, exception.message), status)
  end

  def render_error(json, status)
    render json: json, status: status, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
  end

  def decode_json_api
    return if request.headers["REQUEST_METHOD"] == "GET" ||
      request.headers["Content-Type"] != "application/vnd.api+json" ||
      request.body.read.empty?

    merge_params
  end

  def merge_params
    params.merge!(ActiveSupport::JSON.decode(request.body.string))
  end

  FALSE_VALUES = ActiveModel::Type::Boolean::FALSE_VALUES
  private_constant :FALSE_VALUES

  # Get a parameter as a boolean value.
  # 'false', '0' (or if param is not present) are false-y.
  # @return [true, false]
  def param?(name)
    param = params[name.to_s]
    if param.to_s.blank?
      nil
    else
      !FALSE_VALUES.include?(param)
    end
  end

  class ApiError
    include ActiveModel::Model

    def initialize(code, message)
      errors.add(code, message)
    end
  end
end
