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
        ranked: 0,
        total: Resource.count
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
        ranked: 0,
        total: Resource.count
      },
      countries: retrieve_countries_data
    }

    render json: metrics, status: :ok
  end

  private

  def uniq_languages_per_country(country = nil)
    resource_score_languages = if country.present?
                                 ResourceScore.where(country: country).select(:lang).distinct.pluck(:lang)
                               else
                                 ResourceScore.select(:lang).distinct.pluck(:lang)
                               end
    # resource_default_order_languages = ResourceDefaultOrder.select(:lang).distinct.pluck(:lang)
    resource_default_order_languages = []
    languages = (resource_score_languages + resource_default_order_languages).flatten
    languages.uniq
  end

  def uniq_countries
    ResourceScore.select(:country).distinct.pluck(:country)
  end

  def retrieve_lessons_data(country, lang)
    {
      default: Resource.left_joins(:resource_scores).joins(:resource_type).where(
        resource_types: { name: 'lesson' }, resource_scores: { id: nil, lang: lang }
      ).count,
      featured: Resource.joins(:resource_type, :resource_scores).where(
        resource_types: { name: 'lesson' }, resource_scores: { featured: true, lang: lang, country: country }
      ).count,
      ranked: 0
    }
  end

  def retrieve_tools_data(country, lang)
    {
      default: Resource.left_joins(:resource_scores).joins(:resource_type).where(
        resource_types: { name: 'tract' }, resource_scores: { id: nil, lang: lang }
      ).count,
      featured: Resource.joins(:resource_type, :resource_scores).where(
        resource_types: { name: 'tract' }, resource_scores: { featured: true, lang: lang, country: country }
      ).count,
      ranked: 0
    }
  end

  def retrieve_language_data(country, lang)
    {
      language: lang,
      lessons: retrieve_lessons_data(country, lang),
      tools: retrieve_tools_data(country, lang)
    }
  end

  def retrieve_countries_data
    uniq_countries.map do |country|
      languages = uniq_languages_per_country(country)
      {
        country_code: country,
        languages: languages.map { |lang| retrieve_language_data(country, lang) }
      }
    end
  end
end
