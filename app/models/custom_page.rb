# frozen_string_literal: true

class CustomPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page

  def self.upsert(params)
    translation_id = params[:translation_id]
    page_id = params[:page_id]
    structure = params[:structure]

    create!(translation_id: translation_id, page_id: page_id, structure: structure)
    :created
  rescue
    existing = find_by(translation_id: translation_id, page_id: page_id)
    existing.update(params.permit(:structure))
    :no_content
  end
end
