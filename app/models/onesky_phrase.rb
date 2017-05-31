# frozen_string_literal: true

class OneskyPhrase < ActiveRecord::Base
  belongs_to :page

  validates :text, presence: true
  validates :page, presence: true
  validates :onesky_id, presence: true, uniqueness: true

  before_validation :set_onesky_id, on: :create
  validate do
    errors.add('page', 'Does not use OneSky.') unless page.resource.uses_onesky?
  end

  private

  def set_onesky_id
    self.onesky_id ||= SecureRandom.uuid
  end
end
