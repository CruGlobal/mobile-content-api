# frozen_string_literal: true

class CustomPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page

  validates :structure, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }
end
