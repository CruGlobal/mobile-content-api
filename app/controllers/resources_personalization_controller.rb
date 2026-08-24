# frozen_string_literal: true

class ResourcesPersonalizationController < ApplicationController
  def featured
    lang_code = params.dig(:filter, :lang)
    country = params.dig(:filter, :country)

    unless lang_code.present? && country.present?
      return render json: {errors: [{detail: "Error: Language and Country Filters are required."}]},
        status: :bad_request
    end

    language = find_language!(lang_code)

    featured_resources = all_featured_resources(
      language: language,
      country: country,
      resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
    )

    render json: featured_resources, include: params[:include], fields: field_params, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  def ranked
    lang_code = params.dig(:filter, :lang)
    country = params.dig(:filter, :country)

    unless lang_code.present? && country.present?
      return render json: {errors: [{detail: "Error: Language and Country Filters are required."}]},
        status: :bad_request
    end

    language = find_language!(lang_code)

    ranked_resources = all_ranked_resources(
      language: language,
      country: country,
      resource_types: params.dig(:filter, :"resource-type")
    )

    render json: ranked_resources, include: params[:include], fields: field_params, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  def default_order
    lang = params.dig(:filter, :lang)

    unless lang.present?
      return render json: {errors: [{detail: "Error: Language Filter is required."}]},
        status: :bad_request
    end

    language = find_language!(lang)

    default_order_resources = all_default_order_resources(
      language: language,
      resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
    )

    render json: default_order_resources, include: params[:include], fields: field_params, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  private

  def find_language!(code)
    language = Language.find_by_code(code)
    raise InvalidRequestError, "Language not found for code: #{code}" unless language.present?

    language
  end

  def all_featured_resources(language:, country:, resource_type: nil)
    scope = Resource.includes(:resource_scores).left_joins(:resource_scores)
      .where(resource_scores: {featured: true})
      .joins(resource_scores: :language).where(languages: {id: language.id})
      .where("resource_scores.country = LOWER(:country)", country:)

    if resource_type.present?
      scope = scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase})
    end

    scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
    resource_scores.score DESC NULLS LAST, \
    resources.created_at DESC")
  end

  def all_ranked_resources(language:, country:, resource_types: nil)
    scope = Resource.includes(:resource_scores).left_joins(:resource_scores)
      .where.not(resource_scores: {score: nil})
      .joins(resource_scores: :language).where(languages: {id: language.id})
      .where("resource_scores.country = LOWER(:country)", country:)

    type_names = Array(resource_types).flat_map { |t| t.split(",") }.map(&:downcase)
    scope = scope.joins(:resource_type).where(resource_types: {name: type_names}) if type_names.any?

    scope.order("resource_scores.score DESC, resources.created_at DESC")
  end

  def all_default_order_resources(language:, resource_type: nil)
    scope = Resource.joins(:resource_default_orders)
      .joins(resource_default_orders: :language).where(languages: {id: language.id})

    if resource_type.present?
      scope = scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase})
    end
    scope.order("resource_default_orders.position ASC NULLS LAST, resources.created_at DESC")
  end
end
