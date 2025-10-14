# frozen_string_literal: true

class Resources::FeaturedController < ApplicationController
  before_action :authorize!, only: %i[create destroy]

  def index
    lang = params[:lang]
    country = params[:country]
    json = featured_resources_json(lang:, country:)

    render json: json, include: params[:include], status: :ok
  end

  def create
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
  rescue ActiveRecord::RecordNotFound
    render json: {
      errors: [{ source: { pointer: '/data/attributes/id' }, detail: "Couldn't find ResourceScore with ID=#{params[:id]}" }]
    }, status: :not_found
  rescue StandardError => e
    render json: { errors: [{ source: { pointer: '/data/attributes/id' }, detail: e.message }] },
           status: :unprocessable_entity
  end

  private

  def featured_resources_json(lang:, country:)
    scope = Resource.includes(:resource_scores).left_joins(:resource_scores).where(resource_scores: { featured: true })

    if lang.present?
      # Query for resources at a given language if param is present
      scope = scope.where('resource_scores.lang = LOWER(:lang)', lang:)
    end

    if country.present?
      # Query for resources at a given country if param is present
      scope = scope.where('resource_scores.country = LOWER(:country)', country:)
    end

    scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
      resource_scores.score DESC NULLS LAST, resource_scores.default_order ASC NULLS LAST, \
      resources.created_at DESC")
  end

  def create_params
    params.require(:data).require(:attributes).permit(
      :resource_id, :lang, :country, :score, :featured_order, :featured, :default_order
    )
  end
end
