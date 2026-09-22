# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Setup: Database", "env RAILS_ENV=test bin/rails db:create db:schema:load"
  step "Setup: Service credential", "test -e config/secure/service_account_cred.json || cp spec/fixtures/service_account_cred.json.actions config/secure/service_account_cred.json"

  step "Style: Ruby", "bundle exec standardrb --format simple"

  step "Security: Gem audit", "bin/bundler-audit check --update"
  step "Security: Brakeman code analysis", "bin/brakeman --no-pager"
  step "Tests: RSpec", "env CI=true RAILS_ENV=test bundle exec rspec --color"
  # step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
