# frozen_string_literal: true

class UsesOneskyValidator < ActiveModel::Validator
  def validate(model)
    model.errors.add('resource', 'Does not use OneSky.') unless model.resource.uses_onesky?
  end
end
