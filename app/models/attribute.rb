# frozen_string_literal: true

class Attribute < ActiveRecord::Base
  belongs_to :resource

  has_many :translated_attributes

  validates :key, format: { with: /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/ }
end
