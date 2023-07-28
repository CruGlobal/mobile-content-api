# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Fields

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
    # requested is authorized if using okta and user is admin
    return if current_user&.admin

    render_unauthorized
  end

  def authorization
    @authorization ||= AuthToken.decode(request.headers["Authorization"])
  end

  def current_user_id
    @current_user_id ||= authorization.is_a?(Array) && authorization.first.is_a?(Hash) && authorization.first.with_indifferent_access[:user_id]
  end

  def current_user
    return @current_user if @current_user
    return nil unless current_user_id

    @current_user = User.find_by(id: current_user_id)
  end

  def render_unauthorized
    authorization = AccessCode.new
    authorization.errors.add(:id, "Unauthorized")
    render_error(authorization, :unauthorized) # 401
  end

  def render_forbidden
    authorization = AccessCode.new
    authorization.errors.add(:id, "Forbidden")
    render_error(authorization, :forbidden) # 403
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

  def convert_hyphen_to_dash
    params.deep_transform_keys! { |key| key.tr("-", "_") }
  end

  def formatted_errors(error)
    error.record.errors.flat_map do |attribute, errors|
      errors.map { |error_message| { detail: "#{attribute} #{error_message}" } }
    end
  end
end
