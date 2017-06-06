# frozen_string_literal: true

class FollowUp
  include ActiveModel::Validations

  attr_accessor :email, :language

  validates :email, presence: true
  validates :language, presence: true
end
