# frozen_string_literal: true

class ResourceType < ActiveRecord::Base
  # The app's Tools list is one list: tracts and CYOA tools sit side by side,
  # filed under the same categories, and are featured, ranked and defaulted
  # together. "tool" is the name a client sends to mean that whole family. It
  # is not a row in this table; it expands to the type names below, so one
  # ordering write covers both formats and neither can drift from the other.
  # The row names (tract, cyoa) describe the XML format, not the kind of thing
  # a user sees.
  TOOL = "tool"
  TOOL_TYPE_NAMES = %w[tract cyoa].freeze

  # What a client may name when writing a featured, ranked or default order.
  # The individual tool formats stay accepted for older callers; a client that
  # wants the ordering the app shows should send TOOL.
  ORDERABLE_NAMES = (["lesson", TOOL] + TOOL_TYPE_NAMES).freeze

  validates :name, presence: true, uniqueness: true
  validates :dtd_file, presence: true
  validate do
    errors.add("dtd-file", "Does not exist.") unless File.exist?("public/xmlns/#{dtd_file}")
  end

  # The concrete type names a client-facing name covers.
  #   expand_name("tool")  => ["tract", "cyoa"]
  #   expand_name("Tract") => ["tract"]
  def self.expand_name(name)
    normalized = name.to_s.downcase
    (normalized == TOOL) ? TOOL_TYPE_NAMES : [normalized]
  end

  # Resource types a client-facing name covers; empty when the name is unknown.
  scope :named, ->(name) { where(name: expand_name(name)) }

  # Resolves the type name a client sent with a featured, ranked or default
  # order save into the resource_type ids that save should cover:
  #   "tool"   => [tract.id, cyoa.id]
  #   "lesson" => [lesson.id]
  # Raises when the name cannot be used, with the reason in the message. "not
  # found" (a typo or unknown name) and "not supported" (a real type such as
  # article or metatool, which has no ordering in the app) are kept distinct
  # so the client can tell the two apart.
  #
  # @raise [InvalidRequestError]
  def self.orderable_ids_for!(name)
    normalized = name.to_s.downcase

    unless normalized == TOOL || exists?(name: normalized)
      raise InvalidRequestError, "ResourceType '#{name}' not found"
    end

    unless ORDERABLE_NAMES.include?(normalized)
      raise InvalidRequestError, "ResourceType '#{name}' is not supported"
    end

    named(normalized).pluck(:id)
  end
end
