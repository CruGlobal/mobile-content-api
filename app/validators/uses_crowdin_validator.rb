# frozen_string_literal: true

class UsesCrowdinValidator < ActiveModel::Validator
  def validate(model)
    model.errors.add("resource", "Does not use CrowdIn.") unless model.resource.uses_crowdin?
  end
end 