# frozen_string_literal: true

# A single (country, language) grant letting a non-admin user edit ResourceScores.
#
# Stored flat as pairs; the API serves them nested by country
# ({"mx" => ["es"], "us" => ["en", "es"]}) to match how the org chart reads.
# A NULL language means "every language in this country" and serializes as "*".
class ResourceScorePermission < ApplicationRecord
  include CountryCodes

  ALL_LANGUAGES = "*"

  belongs_to :user
  belongs_to :language, optional: true

  validate :grant_is_unique

  scope :for_country, ->(country) { where(country: country.to_s.downcase) }

  # Does this grant cover the given (country, language_id) pair?
  def covers?(country, language_id)
    return false if country.blank?

    self.country == country.to_s.downcase &&
      (self.language_id.nil? || self.language_id == language_id)
  end

  private

  # Mirrors the partial unique indexes so the API returns a 422 rather than
  # surfacing a RecordNotUnique.
  def grant_is_unique
    return if user_id.blank? || country.blank?

    existing = ResourceScorePermission
      .where(user_id: user_id, country: country, language_id: language_id)
      .where.not(id: id)
    return unless existing.exists?

    errors.add(:base, "this user already has that country and language grant")
  end
end
