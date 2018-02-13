# frozen_string_literal: true

class LanguageValidator < ActiveModel::Validator
  def validate(l)
    return if %w[ltr rtl].include?(l.direction)
    l.errors.add(l.direction, "Invalid direction #{l.direction}. Valid values for direction are 'ltr' and 'rtl'")
  end
end
