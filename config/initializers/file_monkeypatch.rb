# File.exists? was removed in Ruby 3.2, but rspec_api_documentation still uses it.

class File
  class << self
    alias_method :exists?, :exist?
  end
end
