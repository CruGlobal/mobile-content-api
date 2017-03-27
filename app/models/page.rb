# frozen_string_literal: true

class Page < ActiveRecord::Base
  belongs_to :resource
  has_many :translation_elements
  has_many :translation_pages
end
