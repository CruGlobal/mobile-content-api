# frozen_string_literal: true

class KeyUtil
  def self.format
    /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/
  end

  def self.lower_key(attribute)
    attribute.key = attribute.key.downcase if attribute.key.present?
  end
end
