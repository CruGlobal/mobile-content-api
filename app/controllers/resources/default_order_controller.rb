# frozen_string_literal: true

module Resources
  class DefaultOrderController < ApplicationController
    before_action :authorize!, only: %i[create destroy update]

    def index
      default_order_resources = all_default_order_resources(
        lang: params.dig(:filter, :lang) || params[:lang],
        resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
      )

      render json: default_order_resources, include: params[:include], status: :ok
    end

    def create
      @resource_default_order = ResourceDefaultOrder.new(create_params)
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
      render json: {errors: [{source: {pointer: "/data/attributes/id"}, detail: e.message}]}, status: :unprocessable_content
    end

    def update
      @resource_default_order = ResourceDefaultOrder.find(params[:id])
      @resource_default_order.update!(create_params)
      render json: @resource_default_order, status: :ok
    rescue => e
      render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
    end

    private

    def all_default_order_resources(lang:, resource_type: nil)
      scope = Resource.joins(:resource_default_orders)

      scope = filter_by_lang(scope, lang)
      scope = filter_by_resource_type(scope, resource_type)

      scope.order("resource_default_orders.position ASC NULLS LAST, resources.created_at DESC")
    end

    def create_params
      params.require(:data).require(:attributes).permit(
        :resource_id, :lang, :position
      )
    end

    def filter_by_lang(scope, lang)
      return scope unless lang.present?

      scope.where("resource_default_orders.lang = LOWER(:lang)", lang:)
    end

    def filter_by_resource_type(scope, resource_type)
      return scope unless resource_type.present?

      scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase})
    end
  end
end
