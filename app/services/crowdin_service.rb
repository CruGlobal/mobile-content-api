# frozen_string_literal: true

require "json"
require "net/http"
require "crowdin-api"

class CrowdinService
  # @return [Hash] of translated phrases from Crowdin
  # Note that Crowdin doesn't have the concept of filenames like OneSky did, so we can just pull ALL phrases
  # and since we only use phrases as needed when building XML, that's OK
  def self.download_translated_phrases(project_id:, language_code:)
    logger.info "Downloading translated phrases for: project id #{project_id} with language: #{language_code}"

    begin
      client

      # Find the language and use its crowdin_code
      language = Language.find_by(code: language_code)
      raise("Can't find language #{language_code}") unless language
      raise("Language #{language_code} has no crowdin_code") unless language.crowdin_code

      # Grab export url - this is the best way I've found to get all translations for a language -AR
      r = client.export_project_translation({targetLanguageId: language.crowdin_code, format: "crowdin-json"}, nil, project_id)

      # grab dump data - crowdin-json format returns a direct hash
      response = Net::HTTP.get_response(URI.parse(r["data"]["url"]))
      crowdin_json_export = response.body
      translations = JSON.parse(crowdin_json_export)

      translations
    rescue => e
      logger.error "Error downloading translated phrases from Crowdin: #{e.message}"
      {}
    end
  end

  def self.client
    @client ||= ::Crowdin::Client.new do |config|
      config.api_token = ENV.fetch("CROWDIN_API_TOKEN")
    end
  end

  private

  class << self
    private

    def logger
      Rails.logger
    end
  end
end
