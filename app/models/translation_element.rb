# frozen_string_literal: true

class TranslationElement < ActiveRecord::Base
  belongs_to :page

  validates :text, presence: true
  validates :page, presence: true
  validates :onesky_phrase_id, presence: true, uniqueness: true

  before_validation :set_onesky_phrase_id, on: :create

  private

  def set_onesky_phrase_id
    self.onesky_phrase_id ||= SecureRandom.uuid
  end
end
