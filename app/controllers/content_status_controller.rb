class ContentStatusController < ApplicationController
  def index
    metrics = {
      tools: {
        default: Language.joins(resource_default_orders: { resource: :resource_type }).where(
          resource_types: { name: 'tract' }
        ).distinct('languages.id').count,
        featured: Language.joins(resource_scores: { resource: :resource_type }).where(
          resource_types: { name: 'tract' },
          resource_scores: { featured: true }
        ).distinct('languages.id').count,
        ranked: Language.joins(resource_scores: { resource: :resource_type }).where(
          resource_types: { name: 'tract' }
        ).where.not(resource_scores: { score: nil }).distinct('languages.id').count,
        total: Language.joins(resource_scores: { resource: :resource_type }).where(resource_types: { name: 'tract' }).distinct('languages.id').count
      },
      lessons: {
        default: Language.joins(resource_default_orders: { resource: :resource_type }).where(
          resource_types: { name: 'lesson' }
        ).distinct('languages.id').count,
        featured: Language.joins(resource_scores: { resource: :resource_type }).where(
          resource_types: { name: 'lesson' },
          resource_scores: { featured: true }
        ).distinct('languages.id').count,
        ranked: Language.joins(resource_scores: { resource: :resource_type }).where(
          resource_types: { name: 'lesson' }
        ).where.not(resource_scores: { score: nil }).distinct('languages.id').count,
        total: Language.joins(resource_scores: { resource: :resource_type }).where(resource_types: { name: 'lesson' }).distinct('languages.id').count
      },
      countries: retrieve_countries_data
    }

    render json: metrics, status: :ok
  rescue StandardError => e
    render json: { errors: [{ detail: "Error: #{e.message}" }] }, status: :unprocessable_content
  end

  private

  def uniq_countries
    ResourceScore.select(:country).distinct.pluck(:country)
  end

  def retrieve_lessons_data(country, language)
    {
      featured: Resource.joins(:resource_type, resource_scores: :language).where(
        resource_types: { name: 'lesson' }, resource_scores: { featured: true, country: country }
      ).where(resource_scores: { language: language }).count,
      ranked: Resource.joins(:resource_type, resource_scores: :language).where(
        resource_types: { name: 'lesson' }, resource_scores: { country: country }
      ).where(resource_scores: { language: language }).where.not(resource_scores: { score: nil }).count
    }
  end

  def retrieve_tools_data(country, language)
    {
      featured: Resource.joins(:resource_type, resource_scores: :language).where(
        resource_types: { name: 'tract' }, resource_scores: { featured: true, country: country }
      ).where(resource_scores: { language: language }).count,
      ranked: Resource.joins(:resource_type, resource_scores: :language).where(
        resource_types: { name: 'tract' }, resource_scores: { country: country }
      ).where(resource_scores: { language: language }).where.not(resource_scores: { score: nil }).count
    }
  end

  def retrieve_language_data(country, language)
    {
      language_code: language.code.downcase,
      language_name: language.name,
      lessons: retrieve_lessons_data(country, language),
      tools: retrieve_tools_data(country, language),
      last_updated: Resource.joins(:resource_scores).where(
        resource_scores: { country: country, language: language }
      ).maximum(:updated_at)&.strftime('%d-%m-%y') || 'N/A'
    }
  end

  def retrieve_countries_data
    uniq_countries.map do |country|
      {
        country_code: country,
        languages: Language.joins(:resource_scores).where(resource_scores: { country: country }).distinct.map do |language|
          retrieve_language_data(country, language)
        end
      }
    end
  end
end
