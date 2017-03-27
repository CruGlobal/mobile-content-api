# frozen_string_literal: true

class TranslationPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page
end
