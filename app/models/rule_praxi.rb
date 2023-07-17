class RulePraxi < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:openness, :confidence], message: "combination already exists"}

  validate :validate_openness_and_confidence_values, if: :tool_group_id_uniqueness_passed?
  validate :validate_openness_or_confidence, if: :previous_validations_pass?

  private

  def tool_group_id_uniqueness_passed?
    errors[:tool_group_id].empty?
  end

  def validate_openness_or_confidence
    if openness.blank? && confidence.blank?
      errors.add(:base, "Either 'openness' or 'confidence' must be present")
    end
  end

  def validate_openness_and_confidence_values
    validate_array_values(openness, "openness")
    validate_array_values(confidence, "confidence")
  end

  def validate_array_values(attribute_values, attribute_name)
    return if attribute_values.blank?

    attribute_values.each do |value|
      unless value.is_a?(Integer) && (1..5).cover?(value)
        errors.add(attribute_name, "must contain integer values between 1 and 5 or an empty array")
        break
      end
    end
  end

  def previous_validations_pass?
    errors.empty?
  end
end
