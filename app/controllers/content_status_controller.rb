class ContentStatusController < ApplicationController
  def index
    metrics = {
      tools: {
        default: Resource.left_joins(:resource_scores).joins(:resource_type).where(
          resource_types: { name: 'tract' },
          resource_scores: { id: nil }
        ).count,
        featured: Resource.joins(:resource_type, :resource_scores).where(
          resource_types: { name: 'tract' },
          resource_scores: { featured: true }
        ).count,
        ranked: Resource.joins(:resource_type, :resource_scores).where(
          resource_types: { name: 'tract' },
          resource_scores: { featured: true }
        ).where.not(resource_scores: { score: nil }).count,
        total: Resource.joins(:resource_type).where(resource_types: { name: 'tract' }).count
      },
      lessons: {
        default: Resource.left_joins(:resource_scores).joins(:resource_type).where(
          resource_types: { name: 'lesson' },
          resource_scores: { id: nil }
        ).count,
        featured: Resource.joins(:resource_type, :resource_scores).where(
          resource_types: { name: 'lesson' },
          resource_scores: { featured: true }
        ).count,
        ranked: Resource.joins(:resource_type, :resource_scores).where(
          resource_types: { name: 'lesson' },
          resource_scores: { featured: true }
        ).where.not(resource_scores: { score: nil }).count,
        total: Resource.joins(:resource_type).where(resource_types: { name: 'lesson' }).count
      },
      countries: retrieve_countries_data
    }

    render json: metrics, status: :ok
  rescue => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
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
      ranked: 0
    }
  end

  def retrieve_tools_data(country, language)
    {
      featured: Resource.joins(:resource_type, resource_scores: :language).where(
        resource_types: { name: 'tract' }, resource_scores: { featured: true, country: country }
      ).where(resource_scores: { language: language }).count,
      ranked: 0
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
