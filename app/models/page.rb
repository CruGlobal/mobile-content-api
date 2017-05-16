# frozen_string_literal: true

class Page < ActiveRecord::Base
  belongs_to :resource
  has_many :translation_elements
  has_many :custom_pages

  validates :filename, presence: true
  validates :structure, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }
end
