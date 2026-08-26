# frozen_string_literal: true

# A single (country, language) grant letting a non-admin user edit ResourceScores.
#
# Stored flat as pairs; the API serves them nested by country
# ({"mx" => ["es"], "us" => ["en", "es"]}) to match how the org chart reads.
# A NULL language means "every language in this country" and serializes as "*".
class ResourceScorePermission < ApplicationRecord
  ALL_LANGUAGES = "*"

  belongs_to :user
  belongs_to :language, optional: true

  validates :country, presence: true, inclusion: {
    in: CountryCodes::ALPHA2,
    message: "is not a recognized ISO 3166-1 alpha-2 country code"
  }
  validate :grant_is_unique

  before_validation :downcase_country

  scope :for_country, ->(country) { where(country: country.to_s.downcase) }

  # Does this grant cover the given (country, language_id) pair?
  def covers?(country, language_id)
    return false if country.blank?

    self.country == country.to_s.downcase &&
      (self.language_id.nil? || self.language_id == language_id)
  end

  private

  def downcase_country
    self.country = country.downcase if country.present?
  end

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
