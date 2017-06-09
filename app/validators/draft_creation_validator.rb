# frozen_string_literal: true

class DraftCreationValidator < ActiveModel::Validator
  def validate(d)
    existing = Translation.find_by(resource: d.resource, language: d.language, is_published: false)
    return if existing.nil?

    d.errors.add(:id, "Draft already exists for Resource ID: #{d.resource.id} and Language ID: #{d.language.id}")
  end
end
