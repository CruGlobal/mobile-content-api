# frozen_string_literal: true

# Any differences between prod and stage should be handled in ENV variables
require Rails.root.join('config', 'environments', 'production').to_s

Rails.application.routes.default_url_options = {
  host: 'mobile-content-api-stage.cru.org'
}
