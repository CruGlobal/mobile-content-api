# frozen_string_literal: true

require "net/http"
require "json"
require Rails.root.join("lib/tasks/seed_dump_support")

# Loading the per-table SQL export in dump/ into a local database.
#
#   bundle exec rails db:seed_dump:repair    # once, to stamp real ids into the files
#   bundle exec rails db:seed_dump           # load them
#   bundle exec rails db:seed_dump:check     # verify the relationships
#
# The export omits every `id` column while its foreign keys still hold the
# *source* database's ids, so a plain load renumbers the parents and silently
# mis-links the children (translations end up attached to the wrong language,
# pages to the wrong resource). The repair task recovers the true ids from the
# public production API, matching each dump row on a natural key, and rewrites
# the files with an explicit `id`. After that the foreign keys line up and
# loading is a straight replay.

# Parent tables first: a table may only appear after everything it references
# (see `add_foreign_key` in db/schema.rb).
SEED_DUMP_LOAD_ORDER = %w[
  systems
  resource_types
  languages
  tool_groups
  resources
  attributes
  attachments
  pages
  tips
  translations
  translation_attributes
  language_attributes
  resource_default_orders
  resource_scores
  resource_tool_groups
  rule_countries
  rule_languages
  rule_praxes
  translated_attributes
  translated_pages
  custom_manifests
  custom_pages
  custom_tips
  global_activity_analytics
].freeze

SEED_DUMP_API = "https://mobile-content-api.cru.org"

# Child tables whose foreign keys must resolve after a load, as
# [child table, fk column, parent table].
SEED_DUMP_RELATIONSHIPS = [
  %w[resources system_id systems],
  %w[resources resource_type_id resource_types],
  %w[resources metatool_id resources],
  %w[resources default_variant_id resources],
  %w[pages resource_id resources],
  %w[tips resource_id resources],
  %w[attachments resource_id resources],
  %w[attributes resource_id resources],
  %w[translations resource_id resources],
  %w[translations language_id languages],
  %w[translation_attributes translation_id translations],
  %w[language_attributes language_id languages],
  %w[language_attributes resource_id resources],
  %w[resource_default_orders resource_id resources],
  %w[resource_default_orders language_id languages],
  %w[resource_scores resource_id resources],
  %w[resource_tool_groups resource_id resources],
  %w[resource_tool_groups tool_group_id tool_groups],
  %w[rule_countries tool_group_id tool_groups],
  %w[rule_languages tool_group_id tool_groups],
  %w[custom_manifests resource_id resources],
  %w[custom_manifests language_id languages],
  %w[custom_pages page_id pages],
  %w[custom_pages language_id languages],
  %w[custom_tips tip_id tips]
].freeze

namespace :db do
  desc "Load the repaired SQL dump from DIR (default: dump/)"
  task :seed_dump, [:dir] => :environment do |_t, args|
    abort "Refusing to run in production." if Rails.env.production?

    dir = args[:dir].presence || Rails.root.join("dump").to_s
    abort "Not a directory: #{dir}" unless File.directory?(dir)

    files = SeedDump.files_by_table(dir)
    tables = SEED_DUMP_LOAD_ORDER.select { |t| files.key?(t) }
    abort "No dump files found in #{dir}" if tables.empty?

    unrepaired = tables.reject { |t| SeedDump.repaired?(files[t]) || !SeedDump.resolvable?(t) }
    if unrepaired.any?
      abort "These tables still lack an id column: #{unrepaired.join(", ")}\n" \
            "Run `bundle exec rails db:seed_dump:repair` first."
    end

    conn = ActiveRecord::Base.connection
    unless conn.select_value("SELECT usesuper FROM pg_user WHERE usename = CURRENT_USER")
      abort "Need a superuser connection to suspend foreign-key triggers during the load."
    end

    conn.transaction do
      # Children before parents so the truncate itself does not trip the FKs.
      conn.execute("TRUNCATE #{tables.reverse.map { |t| conn.quote_table_name(t) }.join(", ")} RESTART IDENTITY CASCADE")

      # Each table is chunked into many small INSERTs and Rails' foreign keys are
      # NOT DEFERRABLE, so they would be checked at the end of every chunk --
      # before later chunks supply the rows being referenced (resources.metatool_id
      # points within its own table). Verify explicitly afterwards instead.
      conn.execute("SET session_replication_role = replica")

      tables.each do |table|
        conn.execute(File.read(files[table]))
        count = conn.select_value("SELECT COUNT(*) FROM #{conn.quote_table_name(table)}")
        puts format("  %-26s %6d rows", table, count)
      rescue ActiveRecord::StatementInvalid => e
        raise "loading #{table}: #{e.message.lines.first(2).join(" ").strip}"
      end

      conn.execute("SET session_replication_role = origin")
      SeedDump.reset_sequences(conn, tables)
    end

    puts "\nLoaded #{tables.size} tables from #{dir}"
    puts "Verify with: bundle exec rails db:seed_dump:check"
  end

  namespace :seed_dump do
    desc "Stamp real ids into dump/*.sql using ids recovered from the production API"
    task :repair, [:dir] => :environment do |_t, args|
      dir = args[:dir].presence || Rails.root.join("dump").to_s
      abort "Not a directory: #{dir}" unless File.directory?(dir)

      ids = SeedDump.production_ids(refresh: ENV["REFRESH"].present?)
      files = SeedDump.files_by_table(dir)
      SeedDump.repair!(dir, files, ids)
    end

    desc "Report foreign keys left dangling by a dump load"
    task check: :environment do
      conn = ActiveRecord::Base.connection
      broken = 0

      SEED_DUMP_RELATIONSHIPS.each do |child, fk, parent|
        next unless conn.table_exists?(child) && conn.column_exists?(child, fk)
        orphans = conn.select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM #{conn.quote_table_name(child)} c
          WHERE c.#{conn.quote_column_name(fk)} IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM #{conn.quote_table_name(parent)} p WHERE p.id = c.#{conn.quote_column_name(fk)}
            )
        SQL
        next if orphans.zero?
        puts "  DANGLING  #{child}.#{fk} -> #{parent}: #{orphans} rows"
        broken += 1
      end

      puts(broken.zero? ? "  No dangling foreign keys." : "\n#{broken} broken relationship(s).")

      puts "\nSpot check -- a translation's name should be in its own language:"
      conn.select_all(<<~SQL).each { |r| puts format("  %-8s %-24s %s", r["code"], r["language"], r["translated_name"]) }
        SELECT DISTINCT ON (l.id) l.code, l.name AS language, t.translated_name
        FROM translations t JOIN languages l ON l.id = t.language_id
        WHERE t.translated_name IS NOT NULL AND t.translated_name <> ''
        ORDER BY l.id, t.id LIMIT 8
      SQL
    end
  end
end
