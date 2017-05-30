# frozen_string_literal: true

class OneskyPhrase
  include ActiveModel::Model

  validates :text, presence: true
  validates :onesky_id, presence: true

  attr_accessor :text, :onesky_id
end
