# frozen_string_literal: true

class UsesOneskyValidator < ActiveModel::Validator
  def validate(d)
    d.errors.add('resource', 'Does not use OneSky.') unless d.resource.uses_onesky?
  end
end
