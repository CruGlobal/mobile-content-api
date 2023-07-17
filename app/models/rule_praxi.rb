class RulePraxi < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:openness, :confidence], message: "combination already exists"}
  validate :validate_openness_or_confidence

  private

  def validate_openness_or_confidence
    if openness.blank? && confidence.blank?
      errors.add(:base, "Either 'openness' or 'confidence' must be present")
    end
  end
end
