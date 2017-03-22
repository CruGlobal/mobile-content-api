# frozen_string_literal: true

class Language < ActiveRecord::Base
  has_many :translations
end
