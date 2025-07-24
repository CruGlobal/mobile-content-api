# frozen_string_literal: true

require "json"
require "crowdin-api"
require "auth_util"

module CrowdIn
  # @return [Hash] of translated phrases from CrowdIn
  def self.download_translated_phrases(filename, project_id:, language_code:)
    logger.info "Downloading translated phrases for: #{filename} with language: #{language_code}"

    no_crowdin_project = false
    begin
      client = initialize_client(project_id)
      
      # First, find the file ID using the filename
      files = client.source_files.list_files(project_id)
      file = files["data"].find { |f| f["data"]["name"] == filename }
      
      return {} unless file
      
      file_id = file["data"]["id"]
      
      # Download the translations
      download = client.translations.build_project_file_translation(
        project_id,
        file_id,
        {"targetLanguageId": language_code}
      )
      
      download_url = download["data"]["url"]
      response = RestClient.get download_url
      
      # Parse and return the JSON content
      JSON.parse(response.body)
    rescue => e
      logger.error "Error downloading translated phrases: #{e.message}"
      no_crowdin_project = true
      {}
    end
  end

  # @param filename [String] a (JSON) file path
  def self.push_phrases(filename, project_id:, language_code:, keep_existing: true)
    if filename.is_a?(File)
      file = filename
      filename = filename.path
    else
      file = File.new(filename)
    end

    logger.info "Pushing page with name: #{filename} to CrowdIn with language: #{language_code}"

    client = initialize_client(project_id)
    
    # Upload the file to storage
    storage = client.storages.add_storage(file)
    storage_id = storage["data"]["id"]
    
    # Check if file already exists in CrowdIn
    existing_file = nil
    begin
      files = client.source_files.list_files(project_id)
      existing_file = files["data"].find { |f| f["data"]["name"] == File.basename(filename) }
    rescue => e
      logger.error "Error checking for existing file: #{e.message}"
    end
    
    if existing_file
      # Update existing file
      file_id = existing_file["data"]["id"]
      client.source_files.update_file(
        project_id, 
        file_id, 
        { 
          "storageId": storage_id,
          "updateOption": keep_existing ? "keep_translations" : "clear_translations_and_approvals"
        }
      )
    else
      # Add new file
      client.source_files.add_file(
        project_id,
        {
          "storageId": storage_id,
          "name": File.basename(filename),
          "title": File.basename(filename, ".*"),
          "type": "json",
          "importOptions": {
            "contentSegmentation": true,
            "translateContent": true,
            "translationReplace": keep_existing ? false : true
          }
        }
      )
    end
  end

  private

  def self.initialize_client(project_id)
    Crowdin::Client.new do |config|
      config.api_token = ENV["CROWDIN_API_TOKEN"]
      config.project_id = project_id
      
      # Add organization domain if using Crowdin Enterprise
      if ENV["CROWDIN_ORGANIZATION_DOMAIN"].present?
        config.organization_domain = ENV["CROWDIN_ORGANIZATION_DOMAIN"]
      end
    end
  end

  def download_translated_phrases(filename, **args)
    CrowdIn.download_translated_phrases(filename, **args)
  end

  class << self
    private

    def logger
      Rails.logger
    end
  end
end 