# frozen_string_literal: true

class ResourceScoresController < ApplicationController
  before_action :authorize!, only: %i[create destroy update mass_update mass_update_ranked]

  def index
    lang_code = params.dig(:filter, :lang) || params[:lang]
    resource_scores = all_resource_scores(
      lang_code: lang_code,
      country: params.dig(:filter, :country) || params[:country],
      resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
    )

    render json: resource_scores, include: params[:include], status: :ok
  end

  def create
    sanitized_params = create_params
    language = Language.find_by!(code: create_params[:lang].downcase) if create_params[:lang].present?
    sanitized_params.delete(:lang) if sanitized_params[:lang].present?
    @resource_score = ResourceScore.new(sanitized_params)
    @resource_score.language = language if language.present?
    @resource_score.save!
    render json: @resource_score, status: :created
  rescue => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  def destroy
    @resource_score = ResourceScore.find(params[:id])
    @resource_score.destroy!
    render json: {}, status: :ok
  rescue
    render json: {errors: [{source: {pointer: "/data/attributes/id"}, detail: e.message}]},
      status: :unprocessable_content
  end

  def update
    @resource_score = ResourceScore.find(params[:id])
    sanitized_params = create_params
    if create_params[:lang].present?
      language = Language.where("code = :lang OR LOWER(code) = LOWER(:lang)",
        lang: create_params[:lang]).first
    end
    sanitized_params.delete(:lang) if sanitized_params[:lang].present?
    @resource_score.language = language if language.present?
    @resource_score.update!(sanitized_params)

    render json: @resource_score, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  def mass_update
    country = params.dig(:data, :attributes, :country)&.downcase
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type_name = params.dig(:data, :attributes, :resource_type)&.downcase
    incoming_resource_ids = params.dig(:data, :attributes, :resource_ids) || []

    unless country.present? && lang_code.present? && resource_type_name.present?
      raise "Country, Language, and Resource Type should be provided"
    end

    language = Language.find_by("code = :lang OR LOWER(code) = LOWER(:lang)", lang: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    resource_type = ResourceType.find_by(name: resource_type_name)
    raise "ResourceType '#{resource_type_name}' not found" unless resource_type.present?

    unless %w[lesson tract].include?(resource_type.name.downcase)
      raise "ResourceType '#{resource_type_name}' is not supported"
    end

    unless incoming_resource_ids.is_a?(Array) && incoming_resource_ids.all?(Integer)
      raise "resource_ids is expected to be an array of integers"
    end

    raise "resource_ids is expected to include a maximum of 9 ids" if incoming_resource_ids.length > 9

    if incoming_resource_ids.uniq.length != incoming_resource_ids.length
      raise "resource_ids cannot contain duplicate ids"
    end

    valid_resource_ids = Resource.where(id: incoming_resource_ids, resource_type_id: resource_type.id).pluck(:id)
    invalid_resource_ids = incoming_resource_ids - valid_resource_ids
    if invalid_resource_ids.any?
      raise %(Resources not found or do not match the provided resource type.
         Invalid IDs: #{invalid_resource_ids.join(", ")})
    end

    current_scores = ResourceScore
      .joins(:resource)
      .where(country: country, language_id: language.id)
      .where(resources: {resource_type_id: resource_type.id})
      .order(:featured_order)
      .lock
      .to_a

    ResourceScore.transaction do
      current_scores.each do |rs|
        rs.update!(featured: false, featured_order: nil)
      end

      scores_by_resource_id = current_scores.index_by(&:resource_id)
      incoming_resource_ids.each_with_index do |resource_id, index|
        relevant_score = scores_by_resource_id[resource_id]
        if relevant_score
          relevant_score.update!(featured: true, featured_order: index + 1)
        else
          ResourceScore.create!(
            resource_id: resource_id,
            country: country,
            language_id: language.id,
            featured_order: index + 1,
            featured: true
          )
        end
      end
      current_scores.each do |rs|
        soft_delete_featured_score(rs) unless incoming_resource_ids.include?(rs.resource_id)
      end
    end

    resulting_resource_scores = ResourceScore
      .joins(:resource)
      .where(country: country, language_id: language.id, featured: true)
      .where(resources: {resource_type_id: resource_type.id})
      .order(:featured_order)

    render json: resulting_resource_scores, include: params[:include], status: :ok
  rescue => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  end

  def mass_update_ranked
    country = params.dig(:data, :attributes, :country)&.downcase
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type_name = params.dig(:data, :attributes, :resource_type)&.downcase
    incoming_resource_array = params.dig(:data, :attributes, :ranked_resources) || []
    symbolized_incoming_resource_array = incoming_resource_array.map { |r| r.to_unsafe_h.deep_symbolize_keys }

    unless country.present? && lang_code.present? && resource_type_name.present?
      raise "Country, Language, and Resource Type should be provided"
    end

    language = Language.find_by("code = :lang OR LOWER(code) = LOWER(:lang)", lang: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    resource_type = ResourceType.find_by(name: resource_type_name)
    raise "ResourceType '#{resource_type_name}' not found" unless resource_type.present?

    unless %w[lesson tract].include?(resource_type.name.downcase)
      raise "ResourceType '#{resource_type_name}' is not supported"
    end

    incoming_resource_ids = symbolized_incoming_resource_array.map { |r| r[:resource_id] }
    if incoming_resource_ids.uniq.length != incoming_resource_ids.length
      raise "resource_ids cannot contain duplicate ids"
    end

    valid_resource_ids = Resource.where(id: incoming_resource_ids, resource_type_id: resource_type.id).pluck(:id)
    invalid_resource_ids = incoming_resource_ids - valid_resource_ids
    if invalid_resource_ids.any?
      raise "Resources not found or do not match the provided resource type.
         Invalid resource ids: #{invalid_resource_ids.join(", ")}"
    end

    current_scores = ResourceScore
      .joins(:resource)
      .where(country: country, language_id: language.id)
      .where(resources: {resource_type_id: resource_type.id})
      .order(score: :desc)
      .lock
      .to_a

    ResourceScore.transaction do
      scores_by_resource_id = current_scores.index_by(&:resource_id)

      symbolized_incoming_resource_array.each do |incoming_resource|
        resource_id = incoming_resource[:resource_id]
        score = incoming_resource[:score]

        relevant_score = scores_by_resource_id[resource_id]

        if relevant_score
          relevant_score.update!(score: score)
        else
          ResourceScore.create!(
            resource_id: resource_id,
            country: country,
            language_id: language.id,
            score: score
          )
        end
      end
      preserved_resource_ids = symbolized_incoming_resource_array
        .filter_map { |r| r[:resource_id] if r[:score].present? }
        .to_set

      current_scores.each do |rs|
        soft_delete_ranked_score(rs) unless preserved_resource_ids.include?(rs.resource_id)
      end
    end

    resulting_resource_scores = ResourceScore
      .joins(:resource)
      .where(country: country, language_id: language.id)
      .where(resources: {resource_type_id: resource_type.id})
      .where.not(score: nil)
      .order(score: :desc)

    render json: resulting_resource_scores, include: params[:include], status: :ok
  rescue => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  end

  private

  def create_params
    params.require(:data).require(:attributes).permit(
      :resource_id, :lang, :country, :score, :featured_order, :featured
    )
  end

  def all_resource_scores(lang_code:, country:, resource_type: nil)
    scope = ResourceScore.all

    if lang_code.present?
      language = Language.where("code = :lang OR LOWER(code) = LOWER(:lang)", lang: lang_code).first
      scope = scope.left_joins(:language).where(languages: {id: language.id}) if language.present?
    end

    scope = scope.where("LOWER(country) = LOWER(?)", country) if country.present?

    if resource_type.present?
      scope = scope.joins(resource: :resource_type)
        .where(resource_types: {name: resource_type.downcase})
    end

    scope.order("featured_order ASC, featured DESC NULLS LAST, score DESC NULLS LAST, created_at DESC")
  end

  def soft_delete_featured_score(resource_score)
    return if resource_score.nil?

    if resource_score.score.present?
      resource_score.update!(featured: false, featured_order: nil)
    else
      resource_score.destroy!
    end
  end

  def soft_delete_ranked_score(resource_score)
    return if resource_score.nil?

    if resource_score.featured_order.present?
      resource_score.update!(score: nil)
    else
      resource_score.destroy!
    end
  end
end
