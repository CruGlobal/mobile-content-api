class Resources::FeaturedController < ApplicationController
  before_action :authorize!, only: [:create, :destroy]

  def index
    lang = params[:lang]
    country = params[:country]
    json = featured_resources_json(lang:, country:)

    render json: json, status: :ok
  end

  def create
    @resource_score = ResourceScore.new(create_params)
    @resource_score.featured = true
    @resource_score.save!
    render json: @resource_score, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_entity
  end

  def destroy
    @resource_score = ResourceScore.find_by_id!(params[:id])
    @resource_score.destroy!
    render head: :no_content
  rescue ActiveRecord::RecordNotFound => e
    render json: {errors: [{source: {pointer: "/data/attributes/id"}, detail: "Couldn't find ResourceScore with ID=#{params[:id]}"}]}, status: :not_found
  rescue StandardError => e
    render json: {errors: [{source: {pointer: "/data/attributes/id"}, detail: e.message}]}, status: :unprocessable_entity
  end

  private

  def featured_resources_json(lang:, country:)
    scope = Resource.left_joins(:resource_scores).where(resource_scores: { featured: true })

    if lang.present?
      # Query for resources at a given language if param is present
      scope = scope.where("resource_scores.lang = LOWER(:lang)", lang:)
    end

    if country.present?
      # Query for resources at a given country if param is present
      scope = scope.where("resource_scores.country = LOWER(:country)", country:)
    end

    ActiveModelSerializers::SerializableResource.new(
      scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, resource_scores.score DESC NULLS LAST, resources.created_at DESC"),
    ).to_json
  end

  def create_params
    params.require(:data).require(:attributes).permit(:resource_id, :lang, :country, :score, :featured_order)
  end
end
