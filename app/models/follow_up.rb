# frozen_string_literal: true

class FollowUp
  include ActiveModel::Validations

  attr_accessor :email, :name, :language_id

  validates :email, presence: true
  validates :language, presence: true

  def initialize(email, language_id, name = nil)
    self.email = email
    self.language_id = language_id
    self.name = name
  end
end
