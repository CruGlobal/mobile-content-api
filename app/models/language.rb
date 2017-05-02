# frozen_string_literal: true

class Language < ActiveRecord::Base
  has_many :translations

  validates :name, presence: true
  validates :code, presence: true
end
