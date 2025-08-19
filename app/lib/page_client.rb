# frozen_string_literal: true

class PageClient
  def initialize(resource, language_code)
    @resource = resource
    @language_code = language_code
  end

  # I don't think it's critical to push all these files every time a new language is added, but we might as well do so
  # because that will help keep OneSky up to date with the pages and phrases stored in the database.
  def push_new_onesky_translation(keep_existing_phrases = true)
    push_resource_pages(keep_existing_phrases)
    push_name_description
    push_translatable_attributes if @resource.uses_onesky?

    self.class.delete_temp_pages
  rescue => e
    self.class.delete_temp_pages
    raise e
  end

  def self.delete_temp_pages
    temp_dir = Dir.glob("pages/*")
    temp_dir.each { |file| File.delete(file) }
  end

  def self.delete_temp_dir(directory)
    FileUtils.remove_dir(directory)
  end

  private

  def push_resource_pages(keep_existing_phrases)
    @resource.pages.each do |page|
      phrases = {}
      XmlUtil.translatable_nodes(Nokogiri::XML(page.structure)).each { |n| phrases[n["i18n-id"]] = n.content }

      push_page(phrases, page.filename, keep_existing_phrases)
    end
  end

  def push_name_description
    phrases = {name: @resource.name, description: @resource.description}
    push_page(phrases, "name_description.xml", false)
  end

  def push_translatable_attributes
    phrases = @resource.resource_attributes.where(is_translatable: true).pluck(:key, :value).to_h
    push_page(phrases, "attributes.xml", true)
  end

  def push_page(phrases, filename, keep_existing_phrases)
    File.write("pages/#{filename}", phrases.to_json)

    OneSky.push_phrases "pages/#{filename}",
      project_id: @resource.onesky_project_id,
      language_code: @language_code,
      keep_existing: keep_existing_phrases
  end
end
