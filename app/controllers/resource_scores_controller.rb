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
  rescue StandardError => e
    render json: { errors: formatted_errors('record_invalid', e) }, status: :unprocessable_content
  end

  def destroy
    @resource_score = ResourceScore.find(params[:id])
    @resource_score.destroy!
    render json: {}, status: :ok
  rescue StandardError
    render json: { errors: [{ source: { pointer: '/data/attributes/id' }, detail: e.message }] },
           status: :unprocessable_content
  end

  def update
    @resource_score = ResourceScore.find(params[:id])
    sanitized_params = create_params
    if create_params[:lang].present?
      language = Language.where('code = :lang OR LOWER(code) = LOWER(:lang)',
                                lang: create_params[:lang]).first
    end
    sanitized_params.delete(:lang) if sanitized_params[:lang].present?
    @resource_score.language = language if language.present?
    @resource_score.update!(sanitized_params)

    render json: @resource_score, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: formatted_errors('record_invalid', e) }, status: :unprocessable_content
  end

  # TODO: remove logs
  def mu_log(msg)
    Rails.logger.debug("[mass_update] #{msg}")
  end

  def mass_update
    country = params.dig(:data, :attributes, :country)&.downcase
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type_name = params.dig(:data, :attributes, :resource_type)&.downcase
    incoming_resources = params.dig(:data, :attributes, :resource_ids) || []

    mu_log("BEGIN mass update, requested resource IDs: #{incoming_resources}")

    unless country.present? && lang_code.present? && resource_type_name.present?
      raise 'Country, Language, and Resource Type should be provided'
    end

    language = Language.find_by('code = :lang OR LOWER(code) = LOWER(:lang)', lang: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    resource_type = ResourceType.find_by(name: resource_type_name)
    raise "ResourceType '#{resource_type_name}' not found" unless resource_type.present?

    unless %w[lesson tract].include?(resource_type.name.downcase)
      raise "ResourceType '#{resource_type_name}' is not supported"
    end

    current_scores = ResourceScore
                     .joins(:resource)
                     .where(country: country, language_id: language.id)
                     .where(resources: { resource_type_id: resource_type.id })
                     .order(:featured_order)
                     .lock
                     .to_a

    mu_log(
      "Got current scores for country='#{country}', " \
      "lang='#{lang_code}', " \
      "resource_type='#{resource_type_name}': " \
      "#{current_scores.map do |rs|
        { id: rs.id, resource_id: rs.resource_id, featured_order: rs.featured_order, score: rs.score }
      end}"
    )

    ResourceScore.transaction do
      mu_log('Setting featured=false and featured_order=nil for all current scores')
      current_scores.each do |rs|
        rs.update!(featured: false, featured_order: nil)
      end

      scores_by_resource_id = current_scores.index_by(&:resource_id)
      incoming_resources.each_with_index do |resource_id, index|
        relevant_score = scores_by_resource_id[resource_id]
        if relevant_score
          mu_log("found relevant score for resourceID=#{resource_id}, updating featured and featured_order. Initial state: #{relevant_score.attributes}")
          relevant_score.update!(featured: true, featured_order: index + 1)
        else
          mu_log("no relevant score for resourceID=#{resource_id}, creating new score")
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
        soft_delete_featured_score(rs) unless incoming_resources.include?(rs.resource_id)
      end
    end

    resulting_resource_scores = ResourceScore
                                .joins(:resource)
                                .where(country: country, language_id: language.id, featured: true)
                                .where(resources: { resource_type_id: resource_type.id })
                                .order(:featured_order)

    mu_log(
      'Resulting resource scores: ' \
      "#{resulting_resource_scores.map do |rs|
        {
          id: rs.id,
          resource_id: rs.resource_id,
          resource_name: rs.resource.name,
          featured_order: rs.featured_order,
          score: rs.score
        }
      end}"
    )

    render json: resulting_resource_scores, include: params[:include], status: :ok
  rescue StandardError => e
    # TODO: remove error log
    Rails.logger.error("[mass_update] ERROR #{e.class}: #{e.message}")
    render json: { errors: [{ detail: "Error: #{e.message}" }] }, status: :unprocessable_content
  end

  def mass_update_ranked
    country = params.dig(:data, :attributes, :country)&.downcase
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type_name = params.dig(:data, :attributes, :resource_type)&.downcase
    incoming_resources = params.dig(:data, :attributes, :ranked_resources) || []

    mu_log("BEGIN mass update RANKED, requested rankings: #{incoming_resources}")

    unless country.present? && lang_code.present? && resource_type_name.present?
      raise 'Country, Language, and Resource Type should be provided'
    end

    language = Language.find_by('code = :lang OR LOWER(code) = LOWER(:lang)', lang: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    resource_type = ResourceType.find_by(name: resource_type_name)
    raise "ResourceType '#{resource_type_name}' not found" unless resource_type.present?

    unless %w[lesson tract].include?(resource_type.name.downcase)
      raise "ResourceType '#{resource_type_name}' is not supported"
    end

    current_scores = ResourceScore
                     .joins(:resource)
                     .where(country: country, language_id: language.id)
                     .where(resources: { resource_type_id: resource_type.id })
                     .order(score: :desc)
                     .lock
                     .to_a

    mu_log(
      "Got current scores for country='#{country}', " \
      "lang='#{lang_code}', " \
      "resource_type='#{resource_type_name}': " \
      "#{current_scores.map do |rs|
        { id: rs.id, resource_id: rs.resource_id, featured_order: rs.featured_order, score: rs.score }
      end}"
    )

    symbolized_incoming_resources = incoming_resources.map { |r| r.to_unsafe_h.deep_symbolize_keys }

    ResourceScore.transaction do
      scores_by_resource_id = current_scores.index_by(&:resource_id)

      symbolized_incoming_resources.each do |incoming_resource|
        resource_id = incoming_resource[:resource_id]
        score = incoming_resource[:score]

        relevant_score = scores_by_resource_id[resource_id]

        if relevant_score
          mu_log("found relevant score for resourceID=#{resource_id}, updating score to #{score}. Initial state: #{relevant_score.attributes}")
          relevant_score.update!(score: score)
        else
          mu_log("no relevant score for resourceID=#{resource_id}, creating new score")
          ResourceScore.create!(
            resource_id: resource_id,
            country: country,
            language_id: language.id,
            score: score
          )
        end
      end
      preserved_resource_ids = symbolized_incoming_resources
                               .filter_map { |r| r[:resource_id] if r[:score].present? }
                               .to_set

      current_scores.each do |rs|
        soft_delete_ranked_score(rs) unless preserved_resource_ids.include?(rs.resource_id)
      end
    end

    resulting_resource_scores = ResourceScore
                                .joins(:resource)
                                .where(country: country, language_id: language.id)
                                .where(resources: { resource_type_id: resource_type.id })
                                .where.not(score: nil)
                                .order(score: :desc)

    mu_log(
      'Resulting resource scores: ' \
      "#{resulting_resource_scores.map do |rs|
        {
          id: rs.id,
          resource_id: rs.resource_id,
          featured_order: rs.featured_order,
          score: rs.score
        }
      end}"
    )

    render json: resulting_resource_scores, include: params[:include], status: :ok
  rescue StandardError => e
    render json: { errors: [{ detail: "Error: #{e.message}" }] }, status: :unprocessable_content
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
      language = Language.where('code = :lang OR LOWER(code) = LOWER(:lang)', lang: lang_code).first
      scope = scope.left_joins(:language).where(languages: { id: language.id }) if language.present?
    end

    scope = scope.where('LOWER(country) = LOWER(?)', country) if country.present?

    if resource_type.present?
      scope = scope.joins(resource: :resource_type)
                   .where(resource_types: { name: resource_type.downcase })
    end

    scope.order('featured_order ASC, featured DESC NULLS LAST, score DESC NULLS LAST, created_at DESC')
  end

  def soft_delete_featured_score(resource_score)
    return if resource_score.nil?

    if resource_score.score.present?
      mu_log("Detected 'score' for resourceID=#{resource_score.resource_id}, unfeaturing ResourceScore")
      resource_score.update!(featured: false, featured_order: nil)
    else
      mu_log("No 'score' detected for resourceID=#{resource_score.resource_id}, deleting ResourceScore")
      resource_score.destroy!
    end
  end

  def soft_delete_ranked_score(resource_score)
    return if resource_score.nil?

    if resource_score.featured_order.present?
      mu_log("Detected featured resource for resourceID=#{resource_score.resource_id}, updating score to nil")
      resource_score.update!(score: nil)
    else
      mu_log("Featured resource NOT detected for resourceID=#{resource_score.resource_id}, deleting ResourceScore")
      resource_score.destroy!
    end
  end
end
