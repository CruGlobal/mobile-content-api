# Security — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

**Authentication & authorization boundaries**

- Every server endpoint, background job, and privileged action independently verifies the caller's
  identity — never trusts a user id, tenant id, or role passed in from the client
- Authorization is enforced at the data layer (row/tenant scoping, ACL check), not only by hiding UI
- Look for: endpoints added without a session/permission check; ownership checks that compare
  against client-supplied identifiers; policy changes that widen who can read or write a record

**Privileged clients & credentials**

- Admin/service-level clients that bypass normal access control must stay server-only and must never
  be importable from browser or otherwise untrusted code
- Look for: privileged clients imported into client-side modules; secrets read in code that ships to
  the browser; credentials committed to the repo or baked into build artifacts

**Secrets exposure**

- Server-only environment variables must not be exposed through client-visible prefixes, build-time
  inlining, or error payloads
- Look for: new environment-variable references; API keys or tokens in logs, error messages, HTTP
  responses, or analytics events

**Input validation & injection**

- Untrusted input (request bodies, query params, headers, webhooks, third-party payloads, file
  uploads) is validated against an explicit schema before use
- Look for: raw string interpolation into SQL/shell/HTML/templates; parsers fed unvalidated JSON;
  client-side validation with no server-side counterpart; unbounded sizes and counts

**Cross-site and browser-surface risks**

- Look for: raw-HTML injection sinks; unsanitized user content rendered as markup; open redirects
  where a redirect target comes from a query parameter without an allowlist check; missing CSRF
  protection on state-changing requests; weakened CSP or security headers

**Session & cookie handling**

- Look for: session cookies missing `HttpOnly`/`Secure`/`SameSite`; tokens stored where scripts can
  read them; sessions that are not invalidated on logout, password change, or privilege change;
  long-lived or non-rotating credentials

**Webhooks & third-party integrations**

- Look for: webhook handlers that parse and act on a payload before verifying the signature against
  the raw body; missing replay protection; secrets or tokens forwarded to the client

**Supply chain & CI**

- Look for: new dependencies (who maintains them, what they pull in); CI workflow changes that widen
  permission scopes, echo secrets, or let untrusted contributors trigger privileged jobs; changes to
  the review configuration itself that weaken risk scoring or strip checks

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific focus areas (mobile-content-api)

**Which gate guards the endpoint**

- Every endpoint that changes data uses exactly one of the gates in `ApplicationController` and its subclasses: `SecureController` (`before_action :require_admin!`), `WithUserController` (`authorize_user!` plus `authorized_for_subject?` for `/users/:user_id/...` and `me` routes), or `before_action :require_login!` plus a Pundit `authorize` call. A new controller that inherits straight from `ApplicationController` with no gate is public. Check that it is meant to be: `resources#index`, `resource_scores#index`, the `ResourcesPersonalizationController` reads, `views#create` and `follow_ups#create` are the deliberately public ones.
- `current_user` comes only from `AuthToken.decode(request.headers["Authorization"])` and `User.find_by(id:)`. Look for: a user id, `admin` flag or grant read from params and trusted; a new way of reading the token.
- Tokens: `AuthToken` signs HS256 with `JSON_WEB_TOKEN_SECRET`, sets a 1 hour `exp`, and is refreshed on every authenticated response through `X-Auth-Renewal` (`refresh_auth_token`). Look for: longer expirations, a token minted without `exp`, a `decode` that skips verification, the test secret fallback reachable outside `Rails.env.test?`, or token values in custom log lines (`filter_parameters` only covers params).
- OAuth and OIDC sign-in goes through `BaseAuthService.find_user_by_token`: `decode_token`, `validate_token!`, `validate_expected_fields!`, then `setup_user`. A new provider must verify the token with the provider (signature, audience, expiry) in `validate_token!`, not just decode it. Look for: a provider that trusts unverified claims, or `create_user` handling that lets a sign-in attach to someone else's account.
- `ApplicationCable::Connection` identifies no user on purpose: `PublishChannel` and `SubscribeChannel` pair devices by random channel ids checked by `validate_channel_id_format`. Look for: a channel that starts reading or writing user data, which would need real connection auth.
- `/sidekiq` is behind `Rack::Auth::Basic` only in production and staging (`config/routes.rb`); `/docs` (Raddocs) and `/cable` are open. Look for: routes moved outside those guards, or new mounts.
- Production CORS (`config/environments/production.rb`) allows `credentials: true` only for `mobilecontentadmin(-stage).cru.org`; the `origins "*"` block has no credentials. Look for: credentials on the wildcard block, or a widened origin regex.

**Bearer credentials**

- `UserInvite#token` and `invite-url` are bearer credentials: whoever holds one gets the invite's grants, with no email match by design. `UserInviteSerializer` may only render on admin-only routes (`UserInvitesController < SecureController`). Look for: the serializer or the token reaching a non-admin route, a log line, or an error message; a resend path that does not rotate the token (`resend!` calls `generate_unique_secure_token`).

**Security tooling**

- CI runs `bundle exec brakeman -A -q --no-pager -x UnscopedFind` and `bin/bundler-audit check --update` (`.github/workflows/ruby.yml`). Look for: edits to those command lines, and new entries in `config/brakeman.ignore` or `config/bundler-audit.yml`.

### From PR history

- Keep the 401/403 split: no token or an expired token answers 401 (`render_unauthorized`); a valid token without the right role or grant answers 403 (`render_forbidden`). Flag an endpoint or spec that answers 401 to a signed-in user who only lacks rights. Clients treat a 401 as "sign in again".
  <!-- evidence: PR #2045 (review on its fork predecessor #2037), #2048 -->
- When a route loads a subject user by id, use `find_by` and answer an unknown id with the same 403 as an id the caller may not touch, as `WithUserController#authorize_user!` does. Flag `User.find(params[...])` that runs before the permission check: the 404 vs 403 difference lets any signed-in user enumerate user ids. Prefer subclassing `WithUserController` and widening `authorized_for_subject?` over a second hand-rolled `load_user`.
  <!-- evidence: PR #2045 (review on #2037) -->
- Controllers that use Pundit keep `after_action :verify_authorized` unconditional and call `authorize` before any write. For updates, `assign_attributes` first and `authorize` second, so `ResourceScorePolicy#update?` can compare `country_was`/`language_id_was` with the new values. Bulk writes (`mass_update`, `mass_update_ranked`) authorize the whole (country, language, resource type) slice before the transaction. Flag `if: -> { response.successful? }` or any other condition on `verify_authorized`, and `update!` before `authorize`.
  <!-- evidence: PR #2045 (review on #2037), #2046 -->
- `admin` and `grants` are privilege fields. A strong-params permit of `:admin` or grants must sit behind `current_user.admin` (see `UsersController#update_keys`), and admin changes keep the self-demotion and last-admin guards (`UsersController#demotion_refusal`). Flag new permits of these keys on routes a non-admin can reach, and any change that weakens those guards.
  <!-- evidence: PR #2045 (review on #2037), #2048, #2049 -->
- Silence a Brakeman finding with a `config/brakeman.ignore` entry whose `note` says why (as #2048 did for the `:admin` permit in `invite_params`). Changes to the brakeman or bundler-audit flags in `.github/workflows/ruby.yml` are fleet decisions: flag them unless the PR body names the decision.
  <!-- evidence: PR #2020, #2033, #2048 -->
