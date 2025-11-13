# frozen_string_literal: true

module Resources
  class FeaturedController < ApplicationController
    before_action :authorize!, only: %i[create destroy update mass_update]

    def index
      featured_resources = all_featured_resources(
        lang: params.dig(:filter, :lang) || params[:lang],
        country: params.dig(:filter, :country) || params[:country],
        resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
      )

      render json: featured_resources, include: params[:include], status: :ok
    end

    def create
      @resource_score = ResourceScore.new(create_params)
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
      render json: {errors: [{source: {pointer: "/data/attributes/id"}, detail: e.message}]}, status: :unprocessable_content
    end

    def update
      @resource_score = ResourceScore.find(params[:id])
      @resource_score.update!(create_params)
      render json: @resource_score, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
    end

    def mass_update
      current_scores = ResourceScore.where(country: params[:country], lang: params[:lang], featured: true).order(featured_order: :asc).to_a

      incoming_resources = params[:resource_ids] || []
      resulting_resource_scores = []
      
      return render json: current_scores, status: :ok if incoming_resources.empty?

      ResourceScore.transaction do
        ResourceScore::MAX_FEATURED_ORDER_POSITION.times do |index|
          resource_id = incoming_resources[index]
          current_featured_order = index + 1

          if resource_id.nil?
            # Remove any existing resource score at this position
            resource_score_to_remove = current_scores.find { |rs| rs.featured_order == current_featured_order }
            resource_score_to_remove.destroy! if resource_score_to_remove
            next
          end

          incoming_resource_score = current_scores.find { |rs| rs.resource_id == resource_id }
          current_resource_score_at_position = current_scores.find { |rs| rs.featured_order == current_featured_order }

          if incoming_resource_score
            if incoming_resource_score.featured_order != current_featured_order  
              # Incoming ResourceScore exists but at a different position
              # Remove ResourceScore currently at this position, if any
              if current_resource_score_at_position
                current_resource_score_at_position.destroy!
                current_scores.reject! { |rs| rs.id == current_resource_score_at_position.id }
              end

              # Move incoming ResourceScore to the new position
              incoming_resource_score.update!(featured_order: current_featured_order)
              resulting_resource_scores << incoming_resource_score
            else
              # Incoming ResourceScore exists and is already at the correct position
              resulting_resource_scores << incoming_resource_score
              next
            end
          else
            if current_resource_score_at_position  
              # There is a ResourceScore at this position, update it to the new resource_id
              current_resource_score_at_position.update!(resource_id: resource_id)
              resulting_resource_scores << current_resource_score_at_position
            else
              # No ResourceScore at this position, create a new one
              resulting_resource_scores << ResourceScore.create!(
                resource_id: resource_id,
                lang: params[:lang],
                country: params[:country],
                featured: true,
                featured_order: current_featured_order
              )
            end
          end
        end
      end
      render json: resulting_resource_scores, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
    rescue StandardError => e
      render json: {errors: e.message}, status: :unprocessable_content
    end

    private

    def create_params
      params.require(:data).require(:attributes).permit(
        :resource_id, :lang, :country, :score, :featured_order, :featured
      )
    end

    def mass_update_params(resource_score_data)
      resource_score_data.permit(:resource_id, :lang, :country, :score, :featured_order, :featured)
    end

    def all_featured_resources(lang:, country:, resource_type: nil)
      scope = Resource.includes(:resource_scores).left_joins(:resource_scores).where(resource_scores: {featured: true})

      scope = scope.where("resource_scores.lang = LOWER(:lang)", lang:) if lang.present?
      scope = scope.where("resource_scores.country = LOWER(:country)", country:) if country.present?
      scope = scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase}) if resource_type.present?

      scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
      resource_scores.score DESC NULLS LAST, \
      resources.created_at DESC")
    end
  end
end
