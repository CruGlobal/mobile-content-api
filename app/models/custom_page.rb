# frozen_string_literal: true

class CustomPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page
end
