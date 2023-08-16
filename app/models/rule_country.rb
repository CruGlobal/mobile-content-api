class RuleCountry < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:countries, :negative_rule], message: "combination already exists"}
  validate :validate_countries

  private

  def validate_countries
    countries.each do |country|
      unless country.match?(/\A[A-Z]{2}\z/)
        errors.add(:countries, "must contain only ISO-3166 alpha-2 country codes")
        break
      end
    end
  end
end
