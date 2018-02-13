# frozen_string_literal: true

class LanguageValidator < ActiveModel::Validator
  def validate(l)
    if ["ltr", "rtl"].include?(l.direction)
      return
    end
    l.errors.add(l.direction, "Invalid direction #{l.direction}. Valid values for direction are 'ltr' and 'rtl'")
  end
end