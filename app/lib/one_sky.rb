# frozen_string_literal: true

require "json"
require "rest-client"
require "auth_util"
require "digest/md5"

module OneSky
  # @return [Hash] of translated phrases from OneSky
  def self.download_translated_phrases(filename, project_id:, language_code:)
    logger.info "Downloading translated phrases for: #{filename} with language: #{language_code}"

    no_onesky_project = false
    begin
      response = RestClient.get "https://platform.api.onesky.io/1/projects/#{project_id}/translations",
        params: headers(language_code).merge(
          source_file_name: filename, export_file_name: filename
        )
    rescue RestClient::BadRequest
      no_onesky_project = true
    end

    if no_onesky_project || response.code == 204
      logger.info "No translated phrases found for: #{filename} with language: #{language_code}"
      return {}
    end

    JSON.parse(response.body)
  end

  # @param filename [String] a (JSON) file path
  def self.push_phrases(filename, project_id:, language_code:, keep_existing: true)
    if filename.is_a?(File)
      file = filename
      filename = filename.path
    else
      file = File.new(filename)
    end

    logger.info "Pushing page with name: #{filename} to OneSky with language: #{language_code}"

    RestClient.post "https://platform.api.onesky.io/1/projects/#{project_id}/files",
      headers(language_code).merge(
        file: file,
        file_format: "HIERARCHICAL_JSON",
        multipart: true,
        is_keeping_all_strings: keep_existing
      )
  end

  def self.headers(language_code)
    {api_key: ENV["ONESKY_API_KEY"],
     timestamp: AuthUtil.epoch_time_seconds,
     dev_hash: Digest::MD5.hexdigest(AuthUtil.epoch_time_seconds + ENV["ONESKY_API_SECRET"]),
     locale: language_code}
  end

  private

  def download_translated_phrases(*args)
    OneSky.download_translated_phrases(*args)
  end

  class << self
    private

    def logger
      Rails.logger
    end
  end
end
