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

  # What a client may name when writing a featured, ranked or default order. The
  # tool formats are ordered as one list, so a write has to name TOOL: one that
  # named a single format would renumber only that format's rows and leave the
  # other's positions colliding with them. Reads and filters still accept the
  # individual formats; see expand_name.
  ORDERABLE_NAMES = ["lesson", TOOL].freeze

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
  # found" (a typo or unknown name) and "not supported" (a real type that cannot
  # be written on its own: article or metatool, which have no ordering in the
  # app, and tract or cyoa, which are ordered together as TOOL) are kept distinct
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
