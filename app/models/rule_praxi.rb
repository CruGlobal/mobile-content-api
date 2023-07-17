class RulePraxi < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:openness, :confidence], message: "combination already exists"}
  validate :validate_openness_or_confidence, if: :tool_group_id_uniqueness_passed?

  private

  def tool_group_id_uniqueness_passed?
    errors[:tool_group_id].empty?
  end

  def validate_openness_or_confidence
    if openness.blank? && confidence.blank?
      errors.add(:base, "Either 'openness' or 'confidence' must be present")
    end
  end
end
