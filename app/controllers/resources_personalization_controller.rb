# frozen_string_literal: true

class ResourcesPersonalizationController < ApplicationController
  def featured
    lang_code = params.dig(:filter, :lang) || params[:lang]

    if lang_code.present?
      language = Language.find_by_code(lang_code)
      raise InvalidRequestError, "Language not found for code: #{lang_code}" unless language.present?
    end

    featured_resources = all_featured_resources(
      lang_code: lang_code,
      country: params.dig(:filter, :country) || params[:country],
      resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
    )

    render json: featured_resources, include: params[:include], fields: field_params, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  def default_order
    lang = params.dig(:filter, :lang) || params[:lang]

    if lang.present?
      language = Language.find_by_code(lang)
      raise InvalidRequestError, "Language not found for code: #{lang}" unless language.present?
    end

    default_order_resources = all_default_order_resources(
      lang: lang,
      resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
    )

    render json: default_order_resources, include: params[:include], fields: field_params, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]},
      status: :unprocessable_content
  end

  private

  def all_featured_resources(lang_code:, country:, resource_type: nil)
    scope = Resource.includes(:resource_scores).left_joins(:resource_scores).where(resource_scores: {featured: true})

    if lang_code.present?
      language = Language.find_by_code(lang_code)
      scope = scope.joins(resource_scores: :language).where(languages: {id: language.id})
    end

    scope = scope.where("resource_scores.country = LOWER(:country)", country:) if country.present?
    if resource_type.present?
      scope = scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase})
    end

    scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
    resource_scores.score DESC NULLS LAST, \
    resources.created_at DESC")
  end

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
end
