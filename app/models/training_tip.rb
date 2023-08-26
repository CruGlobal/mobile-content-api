# frozen_string_literal: true

class TrainingTip < ActiveRecord::Base
  validates :tool, uniqueness: {scope: [:locale, :tip_id], message: "combination already exists"}
end
