# frozen_string_literal: true

# Any differences between prod and stage should be handled in ENV variables
require Rails.root.join('config', 'environments', 'production').to_s
