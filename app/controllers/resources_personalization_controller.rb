# frozen_string_literal: true

class ResourcesPersonalizationController < ApplicationController
  rescue_from InvalidRequestError do |e|
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  def featured
    lang_code = filter_param(:lang)
    country = filter_param(:country)

    unless lang_code.present? && country.present?
      return render json: {errors: [{detail: "Error: Language and Country Filters are required."}]},
        status: :bad_request
    end

    language = find_language!(lang_code)

    render_resources all_featured_resources(
      language: language,
      country: country,
      resource_types: filter_param(:"resource-type")
    )
  end

  def ranked
    lang_code = filter_param(:lang)
    country = filter_param(:country)

    unless lang_code.present? && country.present?
      return render json: {errors: [{detail: "Error: Language and Country Filters are required."}]},
        status: :bad_request
    end

    language = find_language!(lang_code)

    render_resources all_ranked_resources(
      language: language,
      country: country,
      resource_types: filter_param(:"resource-type")
    )
  end

  def default_order
    lang = filter_param(:lang)

    unless lang.present?
      return render json: {errors: [{detail: "Error: Language Filter is required."}]},
        status: :bad_request
    end

    language = find_language!(lang)

    render_resources all_default_order_resources(
      language: language,
      resource_types: filter_param(:"resource-type")
    )
  end

  private

  def find_language!(code)
    language = Language.find_by_code(code)
    raise InvalidRequestError, "Language not found for code: #{code}" unless language.present?

    language
  end

  def all_featured_resources(language:, country:, resource_types: nil)
    scope = scored_resources(language: language, country: country)
      .where(resource_scores: {featured: true})
    scope = apply_resource_type_filter(scope, resource_types)

    scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
    resource_scores.score DESC NULLS LAST, \
    resources.created_at DESC")
  end

  def all_ranked_resources(language:, country:, resource_types: nil)
    scope = scored_resources(language: language, country: country)
      .where.not(resource_scores: {score: nil})
    scope = apply_resource_type_filter(scope, resource_types)

    scope.order("resource_scores.score DESC, resources.created_at DESC")
  end

  def all_default_order_resources(language:, resource_types: nil)
    scope = Resource.joins(:resource_default_orders)
      .where(resource_default_orders: {language_id: language.id})
    scope = apply_resource_type_filter(scope, resource_types)

    scope.order("resource_default_orders.position ASC NULLS LAST, resources.created_at DESC")
  end

  def scored_resources(language:, country:)
    Resource.includes(:resource_scores).joins(:resource_scores)
      .where(resource_scores: {language_id: language.id, country: country.downcase})
  end

  def apply_resource_type_filter(scope, resource_types)
    type_names = Array(resource_types).flat_map { |t| t.split(",") }.map(&:downcase)
    return scope if type_names.none?

    scope.joins(:resource_type).where(resource_types: {name: type_names})
  end

  def render_resources(resources)
    # the serializer touches resource_type and resource_attributes for every resource
    render json: resources.preload(:resource_type, :resource_attributes),
      include: params[:include], fields: field_params, status: :ok
  end
end
