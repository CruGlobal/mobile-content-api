class AddPublishingErrorsToTranslation < ActiveRecord::Migration[6.1]
  def change
    add_column :translations, :publishing_errors, :text
  end
end
