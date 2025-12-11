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
    language = Language.find_by!(code: create_params[:lang].downcase) if create_params[:lang].present?
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
    resource_type = params.dig(:data, :attributes, :resource_type)
    incoming_resources = params.dig(:data, :attributes, :resource_ids) || []
    resulting_resource_scores = []

    raise "Country, Lang, and Resource Type should be provided" unless country.present? && lang_code.present? && resource_type.present?

    language = Language.find_by(code: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    current_scores = ResourceScore.where(
      country: country, language_id: language.id
    ).order(featured_order: :asc)

    if resource_type.present?
      current_scores = current_scores.joins(resource: :resource_type)
        .where(resource_types: {name: resource_type.downcase})
    end

    current_scores = current_scores.to_a

    if incoming_resources.empty?
      current_scores.each do |rs|
        soft_delete_resource_score(rs)
      end
      current_scores.reject! { |rs| !rs.persisted? }

      return render json: current_scores, include: params[:include], status: :ok
    end

    ResourceScore.transaction do
      ResourceScore::MAX_FEATURED_ORDER_POSITION.times do |index|
        resource_id = incoming_resources[index]
        current_featured_order = index + 1

        if resource_id.nil?
          # Remove any existing resource score at this position
          resource_score_to_remove = current_scores.find { |rs| rs.featured_order == current_featured_order }
          soft_delete_resource_score(resource_score_to_remove)
          next
        end

        incoming_resource_score = current_scores.find { |rs| rs.resource_id == resource_id }
        current_resource_score_at_position = current_scores.find do |rs|
          rs.featured_order == current_featured_order && rs.featured == true
        end

        if incoming_resource_score
          if incoming_resource_score.featured_order != current_featured_order
            # Incoming ResourceScore exists but at a different position
            # Remove ResourceScore currently at this position, if any
            if current_resource_score_at_position
              soft_delete_resource_score(current_resource_score_at_position)
              current_scores.reject! { |rs| rs.id == current_resource_score_at_position.id }
            end

            # Move incoming ResourceScore to the new position
            incoming_resource_score.update!(featured_order: current_featured_order, featured: true)
            resulting_resource_scores << incoming_resource_score
          else
            # Incoming ResourceScore exists and is already at the correct position
            incoming_resource_score.update!(featured: true)
            resulting_resource_scores << incoming_resource_score
            next
          end
        elsif current_resource_score_at_position
          # There is a ResourceScore at this position, update it to the new resource_id
          current_resource_score_at_position.update!(resource_id: resource_id, featured: true)
          resulting_resource_scores << current_resource_score_at_position
        else
          # No ResourceScore at this position, create a new one
          resulting_resource_scores << ResourceScore.create!(
            resource_id: resource_id,
            language_id: language.id,
            country: country,
            featured: true,
            featured_order: current_featured_order
          )
        end
      end
    end
    render json: resulting_resource_scores, include: params[:include], status: :ok
  rescue => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  end

  def mass_update_ranked
    country = params.dig(:data, :attributes, :country)&.downcase
    lang_code = params.dig(:data, :attributes, :lang)&.downcase
    resource_type = params.dig(:data, :attributes, :resource_type)
    incoming_resources = params.dig(:data, :attributes, :ranked_resources) || []
    resulting_resource_scores = []

    raise "Country, Lang, and Resource Type should be provided" unless country.present? && lang_code.present? && resource_type.present?

    language = Language.find_by(code: lang_code)
    raise "Language not found for code: #{lang_code}" unless language.present?

    current_scores = ResourceScore.where(
      country: country, language_id: language.id
    ).order(score: :desc)

    if resource_type.present?
      current_scores = current_scores.joins(resource: :resource_type)
        .where(resource_types: {name: resource_type.downcase})
    end

    current_scores = current_scores.to_a

    if incoming_resources.empty?
      current_scores.each do |rs|
        rs.update!(score: nil)
      end

      return render json: current_scores, include: params[:include], status: :ok
    end

    ResourceScore.transaction do
      incoming_resources.each do |incoming_resource|
        symbolized_incoming_resource = incoming_resource
        resource_id = symbolized_incoming_resource[:resource_id]
        score = symbolized_incoming_resource[:score]
        incoming_resource_score = current_scores.find { |rs| rs.resource_id == resource_id }

        if incoming_resource_score
          # Update existing ResourceScore with new score
          incoming_resource_score.update!(score: score)
          resulting_resource_scores << incoming_resource_score
        else
          # Create new ResourceScore with the provided score
          new_resource_score = ResourceScore.create!(
            resource_id: resource_id,
            language_id: language.id,
            country: country,
            score: score
          )
          resulting_resource_scores << new_resource_score
        end
      end
    end

    # Sort resulting_resource_scores by score descending before rendering
    resulting_resource_scores.sort_by! { |rs| -rs.score.to_i }

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
      language = Language.find_by(code: lang_code.downcase)
      scope = scope.where(language_id: language.id) if language.present?
    end

    scope = scope.where("LOWER(country) = LOWER(?)", country) if country.present?

    if resource_type.present?
      scope = scope.joins(resource: :resource_type)
        .where(resource_types: {name: resource_type.downcase})
    end

    scope.order("featured_order ASC, featured DESC NULLS LAST, score DESC NULLS LAST, created_at DESC")
  end

  def soft_delete_resource_score(resource_score)
    return if resource_score.nil?

    if resource_score.score.present?
      resource_score.update!(featured: false, featured_order: nil)
    else
      resource_score.destroy!
    end
  end
end
