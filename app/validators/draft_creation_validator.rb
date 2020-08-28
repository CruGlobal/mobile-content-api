# frozen_string_literal: true

class DraftCreationValidator < ActiveModel::Validator
  def validate(model)
    existing = Translation.default_scoped.find_by(resource: model.resource, language: model.language, is_published: false)
    return if existing.nil?

    model.errors.add(:id,
      "Draft already exists for Resource ID: #{model.resource.id} and Language ID: #{model.language.id}")
  end
end
