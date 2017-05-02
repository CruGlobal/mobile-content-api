# frozen_string_literal: true

class TranslationElement < ActiveRecord::Base
  belongs_to :page

  before_create :set_onesky_phrase_id

  private

  def set_onesky_phrase_id
    self.onesky_phrase_id ||= SecureRandom.uuid
  end
end
