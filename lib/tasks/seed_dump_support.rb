# frozen_string_literal: true

require "net/http"
require "json"
require_relative "dump_sql"

# Recovers the production ids the SQL export dropped and rewrites dump/*.sql
# with them. See lib/tasks/seed_dump.rake for the why.
module SeedDump
  API = "https://mobile-content-api.cru.org"
  CACHE = "tmp/prod_ids.json"

  # Natural key per table: the columns that identify a dump row well enough to
  # find the same record in production. Foreign keys in the dump are already
  # production ids, so children can be keyed on them directly.
  KEYS = {
    "languages" => %w[code],
    "resources" => %w[abbreviation],
    "pages" => %w[resource_id filename],
    "tips" => %w[resource_id name],
    "attachments" => %w[resource_id sha256],
    "translations" => %w[resource_id language_id version]
  }.freeze

  # Tables whose ids are inferred rather than fetched.
  #   systems      - a single row, id 1 (every resource's `system` relationship)
  #   tool_groups  - not exposed publicly (/tool-groups is admin-only), but the
  #                  three rows are referenced as exactly {1,2,3} and the dump's
  #                  order is corroborated by the rules: row 3 "Syria" owns the
  #                  {SY} country rule, row 2 "Test Arabic" the {ar} language rule.
  ORDINAL = %w[systems tool_groups].freeze

  module_function

  def files_by_table(dir)
    Dir[File.join(dir, "*.sql")].sort.each_with_object({}) do |path, map|
      next if File.size(path).zero?
      header = File.open(path) { |f| f.readline }
      table = header[/INSERT INTO public\."?([a-z_]+)"?/, 1]
      map[table] = path if table
    end
  end

  def repaired?(path)
    header = File.open(path) { |f| f.readline }
    cols = header[/\((.*)\) VALUES/, 1].to_s.split(",").map { |c| c.strip.delete('"') }
    cols.first == "id"
  end

  def resolvable?(table)
    KEYS.key?(table) || ORDINAL.include?(table) || table == "resource_types"
  end

  def get(path)
    uri = URI("#{API}#{path}")
    response = Net::HTTP.get_response(uri)
    raise "GET #{uri} -> #{response.code}" unless response.code == "200"
    JSON.parse(response.body)
  end

  # Build (or reuse) the natural key -> production id map.
  def production_ids(refresh: false)
    cache = Rails.root.join(CACHE)
    if !refresh && cache.exist?
      puts "Using cached production ids (#{CACHE}); pass REFRESH=1 to refetch."
      return JSON.parse(cache.read)
    end

    ids = {"languages" => {}, "resources" => {}, "resource_types_by_abbrev" => {},
           "pages" => {}, "tips" => {}, "attachments" => {}, "translations" => {}}

    puts "Fetching production ids from #{API} ..."
    get("/languages")["data"].each { |r| ids["languages"][r["attributes"]["code"]] = r["id"].to_i }
    puts "  languages     #{ids["languages"].size}"

    resources = get("/resources")["data"]
    resources.each do |r|
      ids["resources"][r["attributes"]["abbreviation"]] = r["id"].to_i
      ids["resource_types_by_abbrev"][r["attributes"]["abbreviation"]] = r["attributes"]["resource-type"]
    end
    puts "  resources     #{ids["resources"].size}"

    resources.each_with_index do |r, i|
      rid = r["id"].to_i
      detail = get("/resources/#{rid}?include=pages,tips,attachments")
      (detail["included"] || []).each do |inc|
        a = inc["attributes"]
        case inc["type"]
        when "page" then ids["pages"]["#{rid}|#{a["filename"]}"] = inc["id"].to_i
        when "tip" then ids["tips"]["#{rid}|#{a["name"]}"] = inc["id"].to_i
        when "attachment" then ids["attachments"]["#{rid}|#{a["sha256"]}"] = inc["id"].to_i
        end
      end
      print "\r  resource detail #{i + 1}/#{resources.size}"
    end
    puts "\r  pages #{ids["pages"].size}, tips #{ids["tips"].size}, attachments #{ids["attachments"].size}"

    get("/translations")["data"].each do |r|
      rel = r["relationships"]
      key = "#{rel["resource"]["data"]["id"]}|#{rel["language"]["data"]["id"]}|#{r["attributes"]["version"]}"
      ids["translations"][key] = r["id"].to_i
    end
    puts "  translations  #{ids["translations"].size}"

    cache.dirname.mkpath
    cache.write(JSON.pretty_generate(ids))
    puts "Cached to #{CACHE}"
    ids
  end

  def repair!(dir, files, ids)
    conn = ActiveRecord::Base.connection
    # resource_types is not exposed as its own endpoint; recover it by joining the
    # dump's resources (abbreviation -> resource_type_id) against production's
    # resource-type name for the same abbreviation.
    type_ids = resource_type_ids(files, ids)

    # Drafts deleted from production since the export get ids above everything
    # real, so they can never collide with a later re-export.
    synthetic = [90_000, ids["translations"].values.max.to_i + 1].max

    SEED_DUMP_LOAD_ORDER.each do |table|
      path = files[table]
      next unless path

      statements = DumpSql.parse(File.read(path))
      next if statements.empty?

      schema_cols = conn.columns(table).map(&:name)
      dump_cols = statements.first[:cols]
      dropped = dump_cols - schema_cols
      keep = dump_cols & schema_cols

      unless resolvable?(table) || dump_cols.include?("id")
        # Not a foreign-key target, so serial assignment is harmless.
        rewrite(path, statements, keep, nil) if dropped.any?
        puts format("  %-26s %5d rows   no id (not referenced)%s", table, statements.sum { |s| s[:rows].size },
          dropped.any? ? "   dropped: #{dropped.join(", ")}" : "")
        next
      end

      if dump_cols.include?("id")
        puts format("  %-26s %5d rows   already has id", table, statements.sum { |s| s[:rows].size })
        next
      end

      index = dump_cols.each_with_index.to_h
      ordinal = 0
      unmatched = 0

      assigned = statements.map do |stmt|
        stmt[:rows].map do |values|
          ordinal += 1
          id =
            if ORDINAL.include?(table)
              ordinal
            elsif table == "resource_types"
              type_ids[DumpSql.unquote(values[index["name"]])]
            else
              key = KEYS[table].map { |c| DumpSql.unquote(values[index[c]]) }.join("|")
              ids[table][key]
            end

          if id.nil?
            if table == "translations"
              id = synthetic
              synthetic += 1
              unmatched += 1
            else
              raise "#{table}: no production id for row #{ordinal} " \
                    "(key #{KEYS[table]&.map { |c| DumpSql.unquote(values[index[c]]) }.inspect})"
            end
          end
          id
        end
      end

      rewrite(path, statements, keep, assigned)
      note = []
      note << "dropped: #{dropped.join(", ")}" if dropped.any?
      note << "#{unmatched} synthetic (gone from prod)" if unmatched.positive?
      puts format("  %-26s %5d rows   ids stamped%s", table, ordinal, note.any? ? "   #{note.join("; ")}" : "")
    end

    puts "\nRepaired dump in #{dir}. Load it with: bundle exec rails db:seed_dump"
  end

  # Rewrite `path` keeping only `keep` columns, optionally prefixing an id.
  def rewrite(path, statements, keep, assigned)
    index = statements.first[:cols].each_with_index.to_h
    rewritten = statements.each_with_index.map do |stmt, si|
      rows = stmt[:rows].each_with_index.map do |values, ri|
        kept = keep.map { |c| values[index[c]] }
        assigned ? [assigned[si][ri].to_s, *kept] : kept
      end
      {table: stmt[:table], cols: assigned ? ["id", *keep] : keep, rows: rows}
    end
    File.write(path, DumpSql.render(rewritten))
  end

  def resource_type_ids(files, ids)
    return {} unless files["resources"] && files["resource_types"]
    statements = DumpSql.parse(File.read(files["resources"]))
    cols = statements.first[:cols].each_with_index.to_h
    return {} unless cols["abbreviation"] && cols["resource_type_id"]

    statements.flat_map { |s| s[:rows] }.each_with_object({}) do |values, map|
      abbrev = DumpSql.unquote(values[cols["abbreviation"]])
      name = ids["resource_types_by_abbrev"][abbrev]
      map[name] = DumpSql.unquote(values[cols["resource_type_id"]]).to_i if name
    end
  end

  def reset_sequences(conn, tables)
    tables.each do |table|
      pk = conn.primary_key(table)
      next unless pk
      conn.execute(<<~SQL)
        SELECT setval(
          pg_get_serial_sequence('#{table}', '#{pk}'),
          GREATEST(COALESCE((SELECT MAX(#{conn.quote_column_name(pk)}) FROM #{conn.quote_table_name(table)}), 1), 1),
          true
        )
      SQL
    end
  end
end
