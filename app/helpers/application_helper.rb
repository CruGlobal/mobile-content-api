# frozen_string_literal: true

module ApplicationHelper
  def self.generate_filename_sha(data, extension = nil)
    filename = Digest::SHA256.hexdigest(data)
    "#{filename}#{extension}"
  end
end
