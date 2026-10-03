# frozen_string_literal: true

require "strscan"

# Parsing/rewriting helpers for the per-table SQL export in dump/.
#
# Each file is a series of chunked `INSERT INTO public.<table> (cols) VALUES
# (...), (...);` statements whose values contain XML -- commas, parentheses,
# newlines and '' -escaped quotes all appear inside string literals -- so the
# tuples have to be scanned rather than split on commas.
module DumpSql
  module_function

  STATEMENT = /INSERT INTO public\."?([a-z_]+)"?\s*\(([^)]*)\)\s*VALUES/m
  PLAIN = /[^'(),]+/ # runs with no structural meaning, consumed in bulk

  # => [{table:, cols: [String], rows: [[raw value text, ...], ...]}, ...]
  def parse(text)
    scanner = StringScanner.new(text)
    statements = []

    while scanner.scan_until(STATEMENT)
      table = scanner[1]
      cols = scanner[2].split(",").map { |c| c.strip.delete('"') }
      rows = []

      loop do
        scanner.skip(/\s+/)
        break unless scanner.scan("(")

        values = []
        current = +""
        depth = 1

        loop do
          chunk = scanner.scan(PLAIN)
          current << chunk if chunk

          if scanner.scan("'")
            current << "'" << scan_string_body(scanner)
          elsif scanner.scan("(")
            depth += 1
            current << "("
          elsif scanner.scan(")")
            depth -= 1
            if depth.zero?
              values << current.strip
              break
            end
            current << ")"
          elsif scanner.scan(",")
            if depth == 1
              values << current.strip
              current = +""
            else
              current << ","
            end
          elsif scanner.eos?
            values << current.strip
            break
          end
        end

        rows << values
        scanner.skip(/\s+/)
        next if scanner.scan(",")
        scanner.scan(";")
        break
      end

      statements << {table: table, cols: cols, rows: rows}
    end

    statements
  end

  # Consumes the remainder of a single-quoted literal (opening quote already
  # taken) and returns it, closing quote included, with '' left intact.
  def scan_string_body(scanner)
    literal = +""
    loop do
      literal << scanner.scan(/[^']*/).to_s
      break unless scanner.scan("'")
      if scanner.scan("'")
        literal << "''" # doubled quote: an escaped ' inside the literal
        next
      end
      literal << "'"
      break
    end
    literal
  end

  # Strip SQL quoting from a raw value so it can be used as a lookup key.
  def unquote(raw)
    return nil if raw.nil?
    value = raw.strip
    return nil if value.casecmp("NULL").zero?
    if value.start_with?("'") && value.end_with?("'") && value.length >= 2
      value[1..-2].gsub("''", "'")
    else
      value
    end
  end

  # Re-emit statements, preserving each value's raw text verbatim.
  def render(statements)
    statements.map { |stmt|
      cols = stmt[:cols].map { |c| %("#{c}") }.join(",")
      tuples = stmt[:rows].map { |values| "\t (#{values.join(",")})" }
      %(INSERT INTO public."#{stmt[:table]}" (#{cols}) VALUES\n#{tuples.join(",\n")};)
    }.join("\n") + "\n"
  end
end
