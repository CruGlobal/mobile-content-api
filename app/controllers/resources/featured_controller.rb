# frozen_string_literal: true

module Resources
  class FeaturedController < ApplicationController
    before_action :authorize!, only: %i[create destroy]

    def index
      featured_resources = all_featured_resources(
        lang: params.dig(:filter, :lang) || params[:lang],
        country: params.dig(:filter, :country) || params[:country],
        resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
      )

      render json: featured_resources, include: params[:include], status: :ok
    end

    def create
      create_params = params.require(:data).require(:attributes).permit(
        :resource_id, :lang, :country, :score, :featured_order, :featured, :default_order
      )
      @resource_score = ResourceScore.new(create_params)
      @resource_score.save!
      render json: @resource_score, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: formatted_errors('record_invalid', e) }, status: :unprocessable_entity
    end

    def destroy
      @resource_score = ResourceScore.find(params[:id])
      @resource_score.destroy!
      render json: {}, status: :ok
    rescue StandardError
      render json: { errors: [{ source: { pointer: '/data/attributes/id' }, detail: e.message }] },
             status: :unprocessable_entity
    end

    private

    def all_featured_resources(lang:, country:, resource_type: nil)
      scope = Resource.includes(:resource_scores).left_joins(:resource_scores).where(resource_scores: { featured: true })

      scope = filter_by_lang(scope, lang)
      scope = filter_by_country(scope, country)
      scope = filter_by_resource_type(scope, resource_type)

      scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
      resource_scores.score DESC NULLS LAST, resource_scores.default_order ASC NULLS LAST, \
      resources.created_at DESC")
    end

    def filter_by_lang(scope, lang)
      return scope unless lang.present?

      scope.where('resource_scores.lang = LOWER(:lang)', lang:)
    end

    def filter_by_country(scope, country)
      return scope unless country.present?

      scope.where('resource_scores.country = LOWER(:country)', country:)
    end

    def filter_by_resource_type(scope, resource_type)
      return scope unless resource_type.present?

      scope.joins(:resource_type).where(resource_types: { name: resource_type.downcase })
    end
  end
end
