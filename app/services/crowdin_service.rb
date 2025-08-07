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

      # the best way I've found to get all translations for a language from crowdin is using the export endpoint -AR
      crowdin_languages_by_name = all_crowdin_languages_by_name
      language = Language.find_by(code: language_code)
      raise("Can't find language #{language_code} in crowdin") unless language && crowdin_languages_by_name.key?(language.name)

      # grab dump url
      r = client.export_project_translation({targetLanguageId: crowdin_languages_by_name[language.name], format: "android"}, nil, project_id)

      # grab dump data and convert it to a hash of key => values
      response = Net::HTTP.get_response(URI.parse(r["data"]["url"]))
      android_format_export = response.body
      doc = Nokogiri::XML(android_format_export)

      translations = {}
      doc.xpath("//resources/string").each do |node|
        key = node["name"]
        value = node.text
        translations[key] = value
      end

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

  # getting the list of languages each time will hopefully mean custom languages get seamlessly picked up (not tested yet)
  def self.all_crowdin_languages_by_name
    languages_by_name = {}
    limit = 100
    offset = 0

    loop do
      response = client.list_languages(limit: limit, offset: offset)
      data = response["data"]
      break if data.empty?

      data.each do |lang_entry|
        lang = lang_entry["data"]
        languages_by_name[lang["name"]] = lang["id"]
      end

      offset += limit
    end

    languages_by_name
  end

  private

  class << self
    private

    def logger
      Rails.logger
    end
  end
end
