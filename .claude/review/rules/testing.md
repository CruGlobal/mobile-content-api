# Testing — Focus Areas

Generic baseline. `/agent-review:init` appends this repo's test conventions (runner, layout,
mocking idioms); keep both.

**Prefer pure-function unit tests**

- Business and domain logic should be extracted out of UI/handler code into plain functions and
  tested directly, rather than asserted through a rendered surface or an HTTP round trip
- Look for: new logic that is only reachable through a component or endpoint, with no seam to test

**Use the repo's existing test framework and idioms**

- Match the repo's test runner, assertion style, mocking helpers, and import conventions. Do not
  assume a framework, rendering harness, or helper library that the repo does not already depend on
- Look for: tests introducing a second runner or harness; imports of libraries absent from the
  manifest

**Mock at module/external boundaries**

- External services (databases, third-party APIs, mail, payments, LLMs) are mocked at the module
  boundary, not by patching global network primitives ad hoc
- Look for: real network or filesystem access in unit tests; mocks that drift from the real
  signature; over-mocking that leaves the logic under test unexercised

**Determinism**

- Time-dependent logic uses the runner's fake-timer/clock control rather than real system time.
  Random values are seeded or injected
- Look for: tests that depend on the current date, timezone, ordering of a map/set, or on another
  test having run first

**Coverage of the shape of the input**

- Every new test should exercise: empty, zero / one / many, boundary values, and at least one happy
  path
- Look for: tests that only assert the happy path; parameters whose invalid values are never tested

**Error paths**

- Validation rejections, rejected promises, timeouts, and the failure branches of domain functions
  are tested, not just success
- Look for: `catch` branches with no covering test

**Test placement and naming**

- Follow the repo's convention for where tests live and how they're named
- Test names describe the behavior asserted, not the function name alone

**Quality gates**

- The repo's test, type-check, lint, and format commands must all pass
- Look for: skipped or `.only` tests left behind; loosely-typed mocks that defeat type checking;
  assertions that can never fail (e.g. asserting on the mock's own return)

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific focus areas (mobile-content-api)

**Runner, layout and helpers**

- RSpec (`rspec-rails`), run with `bundle exec rspec`; CI runs `bundle exec rspec --color` against Postgres 17 and Redis. SimpleCov reports to Codecov, and `codecov/patch` (95% target in `.codecov.yml`) and `codecov/project` are required checks on `master`, so new code without specs blocks the merge.
- Where specs go:
  - `spec/acceptance/<controller>_spec.rb`: rspec_api_documentation (`resource "..." do`, `get "path" do`, `do_request`, `let(:raw_post) { params.to_json }`). `requires_authorization` and `requires_okta_login` from `spec/acceptance_helper.rb` add the "must send a token" and "expired token" 401 examples.
  - `spec/requests/`: authorization matrices and multi-step flows (`type: :request`, a `headers_for(user)` helper built on `AuthToken.encode({user_id: user.id})`).
  - `spec/models/`, `spec/models/xml/`, `spec/services/`, `spec/policies/`, `spec/channels/`, `spec/sidekiq/`, `spec/lib/`, and `spec/package_spec.rb` for zip building.
- Data: FactoryBot factories in `spec/factories/`; `db/seeds.rb` is loaded once before the suite (`Rails.application.load_seed` in `spec/rails_helper.rb`) and transactional fixtures roll back each example. XML and JSON fixtures live in `spec/fixtures/`.
- External calls are stubbed with WebMock (`require "webmock/rspec"`), with shared stubs in `spec/support/test_helpers.rb` and `spec/support/adobe_campaign_stub_helpers.rb`. Specs make no real network calls.
- XSD changes are tested with files under `schema_tests/`, not RSpec (see the content-schema lane).

**What to check**

- Every new endpoint or gate change has the anonymous (401) case, the signed-in-but-not-allowed (403) case, and the allowed case, for each action.
- Policies in `app/policies/` have direct specs in `spec/policies/`, including the "move" case for updates (old and new country or language).
- Time matters for `AuthToken` expiry, `UserInvite::DEFAULT_TTL` and the decayed counts in `user_counters`. Use `travel_to` or `freeze_time` rather than real time; `spec/acceptance/user_counters_controller_spec.rb` already has a tolerance-based example that drifts.

### From PR history

- When a PR changes or removes a behavior, migrate the spec that covered it to assert the new behavior instead of deleting it. Each declared breaking change (old param spelling ignored, retired path returns 404, a status code change) gets its own example so a revert fails loudly. Flag deleted examples whose behavior the PR changes, and ported specs whose URLs or params do not match the current spelling.
  <!-- evidence: PR #2036, #2046 -->
- Do not look records up by hardcoded ids that depend on seed order (`Resource.find(4)`); `db/seeds.rb` warns that some tests depend on resource ids. Use `find_by!(name: ...)` or a factory, and flag new hardcoded-id lookups.
  <!-- evidence: PR #2036 -->
- Test code that calls aws-sdk-s3, rubyzip, nokogiri or another gem whose API moves between versions against the real library, with a stubbed client or a real temp file (`Aws::S3::Client.new(stub_responses: true, ...)` in `spec/package_spec.rb`), not only with a double of the method the code calls. Doubles hid a deprecated `Aws::S3::Object#upload_file` call until the Rails 8.1 upgrade.
  <!-- evidence: PR #2042, #2040, #2052 -->
- Authorization specs cover every action for both an anonymous caller and a signed-in non-admin, and assert 401 and 403 exactly (see `spec/requests/user_invites_spec.rb`). Flag specs that lock in a 401 for a signed-in user who only lacks rights.
  <!-- evidence: PR #2045 (review on #2037), #2048 -->
