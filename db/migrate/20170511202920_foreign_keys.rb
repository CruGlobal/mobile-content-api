class ForeignKeys < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :attachments, :resources
    add_foreign_key :attachments, :translations
    add_foreign_key :attributes, :resources
    add_foreign_key :auth_tokens, :access_codes
    add_foreign_key :custom_pages, :pages
    add_foreign_key :custom_pages, :translations
    add_foreign_key :pages, :resources
    add_foreign_key :resources, :systems
    add_foreign_key :translated_attributes, :attributes
    add_foreign_key :translated_attributes, :translations
    add_foreign_key :translation_elements, :pages
    add_foreign_key :translations, :resources
    add_foreign_key :translations, :languages
    add_foreign_key :views, :resources
  end
end
