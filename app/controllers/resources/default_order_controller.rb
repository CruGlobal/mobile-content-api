# frozen_string_literal: true

module Resources
  class DefaultOrderController < ApplicationController
    before_action :authorize!, only: %i[create destroy update mass_update]

    def index
      lang = params.dig(:filter, :lang) || params[:lang]
      
      if lang.present?
        language = Language.find_by(code: lang.downcase)
        raise "Language not found for code: #{lang.downcase}" unless language.present?
      end

      default_order_resources = all_default_order_resources(
        lang: lang,
        resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
      )

      render json: default_order_resources, include: params[:include], status: :ok
    rescue => e
      render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
    end

    def create
      sanitized_params = create_params
      language = Language.find_by!(code: create_params[:lang].downcase) if create_params[:lang].present?
      sanitized_params.delete(:lang) if sanitized_params[:lang].present?
      @resource_default_order = ResourceDefaultOrder.new(sanitized_params)
      @resource_default_order.language = language if language.present?
      @resource_default_order.save!
      render json: @resource_default_order, status: :created
    rescue => e
      render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
    end

    def destroy
      @resource_default_order = ResourceDefaultOrder.find(params[:id])
      @resource_default_order.destroy!
      render json: {}, status: :ok
    rescue
      render json: {errors: [{source: {pointer: "/data/attributes/id"}, detail: e.message}]},
        status: :unprocessable_content
    end

    def update
      @resource_default_order = ResourceDefaultOrder.find(params[:id])
      sanitized_params = create_params
      language = Language.find_by!(code: create_params[:lang].downcase) if create_params[:lang].present?
      sanitized_params.delete(:lang) if sanitized_params[:lang].present?
      @resource_default_order.language = language if language.present?
      @resource_default_order.update!(sanitized_params)
      render json: @resource_default_order, status: :ok
    rescue => e
      render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
    end

    def mass_update
      lang_code = params.dig(:data, :attributes, :lang)&.downcase
      resource_type = params.dig(:data, :attributes, :resource_type)
      incoming_resources = params.dig(:data, :attributes, :resource_ids) || []
      resulting_resource_default_orders = []

      raise "Lang should be provided" unless lang_code.present?

      language = Language.find_by(code: lang_code)
      raise "Language not found for code: #{lang_code}" unless language.present?

      current_orders = ResourceDefaultOrder.where(language_id: language.id).order(position: :asc)

      if resource_type.present?
        current_orders = current_orders.joins(resource: :resource_type)
          .where(resource_types: {name: resource_type.downcase})
      end

      current_orders = current_orders.to_a

      if incoming_resources.empty?
        current_orders.each do |ro|
          ro.destroy!
        end
        current_orders.reject! { |ro| !ro.persisted? }

        return render json: current_orders, status: :ok
      end

      ResourceDefaultOrder.transaction do
        incoming_resources.each_with_index do |resource_id, index|
          current_position = index + 1

          if resource_id.nil?
            # Remove any existing resource default order at this position
            resource_order_to_remove = current_orders.find { |ro| ro.position == current_position }
            resource_order_to_remove&.destroy!
            next
          end

          incoming_resource_order = current_orders.find { |ro| ro.resource_id == resource_id }
          current_resource_order_at_position = current_orders.find { |ro| ro.position == current_position }

          if incoming_resource_order
            if incoming_resource_order.position != current_position
              # Incoming ResourceDefaultOrder exists but at a different position
              # Remove ResourceDefaultOrder currently at this position, if any
              if current_resource_order_at_position
                current_resource_order_at_position.destroy!
                current_orders.reject! { |ro| ro.id == current_resource_order_at_position.id }
              end

              # Move incoming ResourceDefaultOrder to the new position
              incoming_resource_order.update!(position: current_position)
              resulting_resource_default_orders << incoming_resource_order
            else
              # Incoming ResourceDefaultOrder exists and is already at the correct position
              resulting_resource_default_orders << incoming_resource_order
              next
            end
          elsif current_resource_order_at_position
            # There is a ResourceDefaultOrder at this position, update it to the new resource_id
            current_resource_order_at_position.update!(resource_id: resource_id)
            resulting_resource_default_orders << current_resource_order_at_position
          else
            # No ResourceDefaultOrder at this position, create a new one
            resulting_resource_default_orders << ResourceDefaultOrder.create!(
              resource_id: resource_id,
              language_id: language.id,
              position: current_position
            )
          end
        end
      end
      render json: resulting_resource_default_orders, status: :ok
    rescue => e
      render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
    end

    private

    def all_default_order_resources(lang:, resource_type: nil)
      scope = Resource.joins(:resource_default_orders)

      if lang.present?
        language = Language.find_by(code: lang.downcase)
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
end
