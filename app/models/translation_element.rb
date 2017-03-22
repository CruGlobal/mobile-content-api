# frozen_string_literal: true

class TranslationElement < ActiveRecord::Base
  belongs_to :page
end
