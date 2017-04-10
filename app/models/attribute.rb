# frozen_string_literal: true

class Attribute < ActiveRecord::Base
  belongs_to :resource

  has_many :translated_attributes
end
