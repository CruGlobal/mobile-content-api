# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  has_many :translations
  has_many :pages
end
