module OneSky

  # @return [Hash] of translated phrases from OneSky
  def self.download_translated_phrases(filename, project_id:, language_code:)
    logger.info "Downloading translated phrases for: #{filename} with language: #{language_code}"

    response = RestClient.get "https://platform.api.onesky.io/1/projects/#{project_id}/translations",
                              params: headers(filename, language_code)

    # NOTE: maybe Error::TextNotFoundError should have been a error under a OneSky namespace
    raise Error::TextNotFoundError, 'No translated phrases found for this language.' if response.code == 204
    JSON.parse(response.body)
  end

  private

  def download_translated_phrases(*args)
    OneSky.download_translated_phrases(*args)
  end

  def self.headers(filename, language_code)
    { api_key: ENV['ONESKY_API_KEY'], timestamp: AuthUtil.epoch_time_seconds, dev_hash: HashUtil.dev_hash,
      locale: language_code, source_file_name: filename, export_file_name: filename }
  end

  class << self

    private

    def logger
      Rails.logger
    end

  end

end