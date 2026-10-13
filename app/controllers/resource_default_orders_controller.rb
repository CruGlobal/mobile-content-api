# frozen_string_literal: true

class ResourceDefaultOrdersController < ApplicationController
  before_action :require_admin!, only: %i[create destroy update mass_update]

  def index
    lang = params.dig(:filter, :lang) || params[:lang]
    resource_type = params.dig(:filter, :resource_type) || params[:resource_type]

    if lang.present?
      language = Language.find_by_code(lang)
      raise InvalidRequestError, "Language not found for code: #{lang}" unless language.present?
    end

    default_order_resources = all_default_order_resources(lang: lang, resource_type: resource_type)

    render json: default_order_resources, include: params[:include], status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  def create
    sanitized_params = create_params
    lang = sanitized_params.delete(:lang)

    if lang.present?
      language = Language.find_by_code(lang)
      raise InvalidRequestError, "Language not found for code: #{lang}" unless language.present?
    end

    @resource_default_order = ResourceDefaultOrder.new(sanitized_params)
    @resource_default_order.language = language if language.present?
    @resource_default_order.save!

    render json: @resource_default_order, status: :created
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)},
      status: :unprocessable_content
  end

  def destroy
    @resource_default_order = ResourceDefaultOrder.find(params[:id])
    @resource_default_order.destroy!
    render json: {}, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      errors: [
        {
          source: {pointer: "/data/attributes/id"},
          detail: e.message
        }
      ]
    }, status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {
      errors: [
        {
          source: {pointer: "/data/attributes/id"},
          detail: e.message
        }
      ]
    }, status: :unprocessable_content
  end

  def update
    @resource_default_order = ResourceDefaultOrder.find(params[:id])
    sanitized_params = create_params
    lang = sanitized_params.delete(:lang)

    if lang.present?
      language = Language.find_by_code(lang)
      raise InvalidRequestError, "Language not found for code: #{lang}" unless language.present?

      @resource_default_order.language = language
    end

    @resource_default_order.update!(sanitized_params)

    render json: @resource_default_order, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      errors: [
        {
          source: {pointer: "/data/attributes/id"},
          detail: e.message
        }
      ]
    }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)},
      status: :unprocessable_content
  end

  def mass_update
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type_name = params.dig(:data, :attributes, :resource_type)&.downcase
    incoming_resource_ids = params.dig(:data, :attributes, :resource_ids) || []

    unless lang_code.present? && resource_type_name.present?
      raise InvalidRequestError,
        "Language and Resource Type should be provided"
    end

    language = Language.find_by_code(lang_code)
    unless language.present?
      raise InvalidRequestError,
        "Language not found for code: #{lang_code}"
    end

    resource_type = ResourceType.find_by(name: resource_type_name)
    unless resource_type.present?
      raise InvalidRequestError,
        "ResourceType '#{resource_type_name}' not found"
    end

    unless %w[lesson tract].include?(resource_type.name.downcase)
      raise InvalidRequestError,
        "ResourceType '#{resource_type_name}' is not supported"
    end

    unless incoming_resource_ids.is_a?(Array) && incoming_resource_ids.all?(Integer)
      raise InvalidRequestError,
        "resource_ids is expected to be an array of integers"
    end

    if incoming_resource_ids.length > ResourceDefaultOrder::MAX_DEFAULT_ORDER_POSITION
      raise InvalidRequestError,
        "resource_ids is expected to include a maximum of " \
        "#{ResourceDefaultOrder::MAX_DEFAULT_ORDER_POSITION} ids"
    end

    if incoming_resource_ids.uniq.length != incoming_resource_ids.length
      raise InvalidRequestError,
        "resource_ids cannot contain duplicate ids"
    end

    valid_resource_ids = Resource.where(id: incoming_resource_ids, resource_type_id: resource_type.id).pluck(:id)
    invalid_resource_ids = incoming_resource_ids - valid_resource_ids
    if invalid_resource_ids.any?
      raise InvalidRequestError,
        "Resources not found or do not match the provided resource type. Invalid IDs: #{invalid_resource_ids.join(", ")}"
    end

    ResourceDefaultOrder.transaction do
      current_default_orders = ResourceDefaultOrder
        .joins(:resource)
        .where(language_id: language.id)
        .where(resources: {resource_type_id: resource_type.id})
        .order(position: :asc)
        .lock
        .to_a

      current_default_orders.each do |ro|
        ro.update_column(:position, nil)
      end

      orders_by_resource_id = current_default_orders.index_by(&:resource_id)
      incoming_resource_ids.each_with_index do |resource_id, index|
        relevant_order = orders_by_resource_id[resource_id]

        if relevant_order
          relevant_order.update!(position: index + 1)
        else
          ResourceDefaultOrder.create!(
            resource_id: resource_id,
            language_id: language.id,
            position: index + 1
          )
        end
      end
      current_default_orders.each do |ro|
        ro.destroy! unless incoming_resource_ids.include?(ro.resource_id)
      end
    end
    resulting_default_orders = ResourceDefaultOrder
      .joins(:resource)
      .where(language_id: language.id)
      .where(resources: {resource_type_id: resource_type.id})
      .order(position: :asc)

    render json: resulting_default_orders, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)},
      status: :unprocessable_content
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  private

  def all_default_order_resources(lang:, resource_type: nil)
    scope = Resource.joins(:resource_default_orders)

    if lang.present?
      language = Language.find_by_code(lang)
      scope = scope.joins(resource_default_orders: :language).where(languages: {id: language.id})
    end

    if resource_type.present?
      scope = scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase})
    end

    scope.order("resource_default_orders.position ASC NULLS LAST, resources.created_at DESC")
  end

  def create_params
    params.require(:data).require(:attributes).permit(
      :resource_id, :lang, :position
    )
  end
end
