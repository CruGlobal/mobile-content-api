# frozen_string_literal: true

class LanguageValidator < ActiveModel::Validator
  def validate(model)
    return if %w[ltr rtl].include?(model.direction)
    model.errors.add(model.direction,
      "Invalid direction #{model.direction}. Valid values for direction are 'ltr' and 'rtl'")
  end
end
