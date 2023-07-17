class RulePraxi < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:openness, :confidence], message: "combination already exists"}
  validate :validate_openness_or_confidence, if: :no_openness_or_confidence?

  validates_each :openness, :confidence do |record, attr, value|
    next if value.blank?

    value.each do |v|
      record.errors.add(attr, "must contain integer values between 1 and 5 or an empty array") unless v.is_a?(Integer) && (1..5).cover?(v)
    end
  end

  private

  def no_openness_or_confidence?
    openness.blank? && confidence.blank?
  end

  def validate_openness_or_confidence
    errors.add(:base, "Either 'openness' or 'confidence' must be present")
  end
end
