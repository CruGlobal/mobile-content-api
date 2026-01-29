# frozen_string_literal: true

class ResourceDefaultOrdersController < ApplicationController
  before_action :authorize!, only: %i[create destroy update mass_update]

  def index
    lang = params.dig(:filter, :lang) || params[:lang]
    resource_type = params.dig(:filter, :resource_type) || params[:resource_type]

    if lang.present?
      language = Language.where('code = :lang OR LOWER(code) = LOWER(:lang)', lang: lang).first
      raise "Language not found for code: #{lang}" unless language.present?
    end

    default_order_resources = all_default_order_resources(lang: lang, resource_type: resource_type)

    render json: default_order_resources, include: params[:include], status: :ok
  rescue StandardError => e
    render json: { errors: [{ detail: "Error: #{e.message}" }] }, status: :unprocessable_content
  end

  def create
    sanitized_params = create_params
    if create_params[:lang].present?
      language = Language.where('code = :lang OR LOWER(code) = LOWER(:lang)',
                                lang: create_params[:lang]).first
    end
    sanitized_params.delete(:lang) if sanitized_params[:lang].present?
    @resource_default_order = ResourceDefaultOrder.new(sanitized_params)
    @resource_default_order.language = language if language.present?
    @resource_default_order.save!
    render json: @resource_default_order, status: :created
  rescue StandardError => e
    render json: { errors: formatted_errors('record_invalid', e) }, status: :unprocessable_content
  end

  def destroy
    @resource_default_order = ResourceDefaultOrder.find(params[:id])
    @resource_default_order.destroy!
    render json: {}, status: :ok
  rescue StandardError
    render json: { errors: [{ source: { pointer: '/data/attributes/id' }, detail: e.message }] },
           status: :unprocessable_content
  end

  def update
    @resource_default_order = ResourceDefaultOrder.find(params[:id])
    sanitized_params = create_params
    if create_params[:lang].present?
      language = Language.where('code = :lang OR LOWER(code) = LOWER(:lang)',
                                lang: create_params[:lang]).first
    end
    sanitized_params.delete(:lang) if sanitized_params[:lang].present?
    @resource_default_order.language = language if language.present?
    @resource_default_order.update!(sanitized_params)
    render json: @resource_default_order, status: :ok
  rescue StandardError => e
    render json: { errors: formatted_errors('record_invalid', e) }, status: :unprocessable_content
  end

  # TODO: remove logs
  def mu_log(msg)
    Rails.logger.debug("[mass_update_default] #{msg}")
  end

  def mass_update
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type_name = params.dig(:data, :attributes, :resource_type)&.downcase
    incoming_resource_ids = params.dig(:data, :attributes, :resource_ids) || []

    mu_log("BEGIN mass update, requested resource IDs: #{incoming_resource_ids}")

    raise 'Language and Resource Type should be provided' unless lang_code.present? && resource_type_name.present?

    language = Language.find_by('code = :lang OR LOWER(code) = LOWER(:lang)', lang: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    resource_type = ResourceType.find_by(name: resource_type_name)
    raise "ResourceType '#{resource_type_name}' not found" unless resource_type.present?

    unless %w[lesson tract].include?(resource_type.name.downcase)
      raise "ResourceType '#{resource_type_name}' is not supported"
    end

    unless incoming_resource_ids.is_a?(Array) && incoming_resource_ids.all?(Integer)
      raise 'resource_ids is expected to be an array of integers'
    end

    raise 'resource_ids is expected to include a maximum of 9 ids' if incoming_resource_ids.length > 9

    if incoming_resource_ids.uniq.length != incoming_resource_ids.length
      raise 'resource_ids cannot contain duplicate ids'
    end

    valid_resource_ids = Resource.where(id: incoming_resource_ids, resource_type_id: resource_type.id).pluck(:id)
    invalid_resource_ids = incoming_resource_ids - valid_resource_ids
    if invalid_resource_ids.any?
      raise "Resources not found or do not match the provided resource type. Invalid IDs: #{invalid_resource_ids.join(', ')})" # rubocop:disable Layout/LineLength
    end

    current_default_orders = ResourceDefaultOrder
                             .joins(:resource)
                             .where(language_id: language.id)
                             .where(resources: { resource_type_id: resource_type.id })
                             .order(position: :asc)
                             .lock
                             .to_a

    mu_log(
      "Got current orders for language='#{lang_code}', " \
      "resource_type='#{resource_type_name}': " \
      "#{current_default_orders.map do |rs|
        { id: rs.id, resource_id: rs.resource_id, position: rs.position }
      end}"
    )

    ResourceDefaultOrder.transaction do
      mu_log('Setting position=nil for all current orders')
      current_default_orders.each do |ro|
        # Temporary nil assignment to avoid uniqueness validation conflicts
        ro.update_column(:position, nil)
      end

      orders_by_resource_id = current_default_orders.index_by(&:resource_id)
      incoming_resource_ids.each_with_index do |resource_id, index|
        relevant_order = orders_by_resource_id[resource_id]

        if relevant_order
          mu_log("found relevant default order for resourceID=#{resource_id}, updating to position=#{index + 1}")
          relevant_order.update!(position: index + 1)
        else
          mu_log("no relevant default order for resourceID=#{resource_id}, creating new order")
          ResourceDefaultOrder.create!(
            resource_id: resource_id,
            language_id: language.id,
            position: index + 1
          )
        end
      end
      current_default_orders.each do |ro|
        unless incoming_resource_ids.include?(ro.resource_id)
          mu_log("Deleting default order for resource_id #{ro.resource_id}")
        end

        ro.destroy! unless incoming_resource_ids.include?(ro.resource_id)
      end

      resulting_default_orders = ResourceDefaultOrder
                                 .joins(:resource)
                                 .where(language_id: language.id)
                                 .where(resources: { resource_type_id: resource_type.id })
                                 .order(position: :asc)

      mu_log(
        'Resulting default orders: ' \
        "#{resulting_default_orders.map do |ro|
          {
            id: ro.id,
            resource_id: ro.resource_id,
            position: ro.resource.name
          }
        end}"
      )

      render json: resulting_default_orders, status: :ok
    rescue StandardError => e
      render json: { errors: [{ detail: "Error: #{e.message}" }] }, status: :unprocessable_content
    end
  end

  private

  def all_default_order_resources(lang:, resource_type: nil)
    scope = Resource.joins(:resource_default_orders)

    if lang.present?
      language = Language.where('code = :lang OR LOWER(code) = LOWER(:lang)', lang: lang).first
      scope = scope.joins(resource_default_orders: :language).where(languages: { id: language.id })
    end

    if resource_type.present?
      scope = scope.joins(:resource_type).where(resource_types: { name: resource_type.downcase })
    end

    scope.order('resource_default_orders.position ASC NULLS LAST, resources.created_at DESC')
  end

  def create_params
    params.require(:data).require(:attributes).permit(
      :resource_id, :lang, :position
    )
  end
end
