# frozen_string_literal: true

class OneskyPhrase < ActiveRecord::Base
  belongs_to :page

  validates :text, presence: true
  validates :page, presence: true
  validates :onesky_id, presence: true, uniqueness: true

  before_validation :set_onesky_id, on: :create
  before_save :only_onesky

  private

  def set_onesky_id
    self.onesky_id ||= SecureRandom.uuid
  end

  def only_onesky
    raise 'Cannot be created for projects not using OneSky.' unless page.resource.uses_onesky?
  end
end
