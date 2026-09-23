# frozen_string_literal: true

# Turns the wire shape of a grant map -- {"us" => ["en", "*"]} -- into resolved
# (country, Language-or-nil) pairs, with the same messages the permissions
# endpoint has always returned.
#
# Extracted from ResourceScorePermissionsController so the invite flow can
# validate a grant map when an invite is created and resolve it again when the
# invite is accepted, without a second copy of the rules that could drift.
module ResourceScoreGrants
  module_function

  # @return [Array<Array(String, Language, nil)>] nil language is the wildcard
  # @raise [InvalidRequestError] on a bad country, unknown language, empty
  #   language list or duplicate pair
  def resolve(grants)
    pairs = each_pair(grants) { |country, code| [country, resolve_language(code)] }
    assert_no_duplicates!(pairs)
    pairs
  end

  # Same resolution, but an unresolvable language code is skipped rather than
  # fatal. Used at accept time: a language deleted between an invite being
  # created and being accepted must not lock a legitimate invitee out.
  #
  # @return [Array(Array<Array(String, Language, nil)>, Array<String>)]
  #   the resolved pairs and the "country/code" keys that were skipped
  def resolve_lenient(grants)
    skipped = []
    pairs = each_pair(grants) do |country, code|
      [country, resolve_language(code)]
    rescue InvalidRequestError
      skipped << "#{country}/#{code}"
      nil
    end

    [pairs.compact.uniq, skipped]
  end

  # The canonical storable form: lowercase countries, language codes checked
  # against the languages table, "*" preserved.
  #
  # @return [Hash{String => Array<String>}]
  def normalize_map(grants)
    resolve(grants).each_with_object({}) do |(country, language), map|
      (map[country] ||= []) << (language&.code || ResourceScorePermission::ALL_LANGUAGES)
    end
  end

  def normalized_country(country)
    normalized = country.to_s.downcase
    unless CountryCodes.valid?(normalized)
      raise InvalidRequestError, "'#{country}' is not a recognized ISO 3166-1 alpha-2 country code"
    end

    normalized
  end

  # An explicit "*" is the only way to ask for every language in a country. A
  # missing or blank code is a client bug (a misspelled key gets dropped by
  # permit), so it errors rather than silently granting the whole country.
  def resolve_language(code)
    if code.blank?
      raise InvalidRequestError,
        "lang is required (use \"#{ResourceScorePermission::ALL_LANGUAGES}\" for every language in the country)"
    end

    return nil if code == ResourceScorePermission::ALL_LANGUAGES

    language = Language.find_by_code(code)
    raise InvalidRequestError, "Language not found for code: #{code}" unless language

    language
  end

  # Walks the map, yielding each (normalized country, language code) pair.
  # Accepts a plain Hash (jsonb column, specs) or ActionController::Parameters.
  def each_pair(grants)
    grants = grants.to_unsafe_h if grants.respond_to?(:to_unsafe_h)

    grants.flat_map do |country, langs|
      normalized = normalized_country(country)
      codes = Array(langs)
      if codes.empty?
        raise InvalidRequestError,
          "'#{country}' must list at least one language code " \
          "(use [\"#{ResourceScorePermission::ALL_LANGUAGES}\"] for the whole country, " \
          "or drop the country from the map to revoke it)"
      end

      codes.map { |lang| yield(normalized, lang) }
    end
  end

  def assert_no_duplicates!(pairs)
    duplicates = pairs.tally.select { |_pair, count| count > 1 }.keys
    return if duplicates.empty?

    raise InvalidRequestError,
      "duplicate grants: #{duplicates.map { |country, language| "#{country}/#{language&.code || ResourceScorePermission::ALL_LANGUAGES}" }.join(", ")}"
  end
end
