# frozen_string_literal: true

require "json"
require "crowdin-api"

module Crowdin
  # @return [Hash] of translated phrases from Crowdin
  def self.download_translated_phrases(filename, project_id:, language_code:)
    logger.info "Downloading translated phrases for: #{filename} with language: #{language_code}"

    begin
      crowdin_client = client
      # For string-based projects, we get string translations by language
      # Using the string translations endpoint
      translations_response = crowdin_client.fetch_string_translations(project_id, language_code: language_code)
      
      # Convert the response to the expected format
      translations = {}
      translations_response&.dig("data")&.each do |translation_data|
        string_data = translation_data["data"]
        key = string_data.dig("string", "data", "identifier") || string_data.dig("string", "data", "text")
        translated_text = string_data["text"]
        translations[key] = translated_text if key && translated_text
      end
      
      translations
    rescue => e
      logger.error "Error downloading translated phrases from Crowdin: #{e.message}"
      {}
    end
  end

  def self.client
    @client ||= ::Crowdin::Client.new do |config|
      config.api_token = ENV["CROWDIN_API_TOKEN"]
      config.project_id = ENV["CROWDIN_PROJECT_ID"] if ENV["CROWDIN_PROJECT_ID"]
    end
  end

  private

  def download_translated_phrases(filename, **args)
    Crowdin.download_translated_phrases(filename, **args)
  end

  class << self
    private

    def logger
      Rails.logger
    end
  end
end
