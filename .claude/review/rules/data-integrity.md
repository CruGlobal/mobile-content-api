# Data Integrity — Focus Areas

Generic baseline. This is where domain-specific data invariants belong once `/agent-review:init`
appends them; keep both.

**Access scoping at the data layer**

- Every query and mutation is scoped to the authenticated user/tenant/household. New tables,
  columns, or collections need matching access policies
- Look for: policy changes that widen a `where`/`using`/`with check` clause; queries filtered only
  in application code where a shared or admin connection bypasses the policy

**Validation at external boundaries**

- Payloads from HTTP requests, webhooks, queues, and third-party APIs are parsed against an explicit
  schema before use
- Look for: external JSON consumed without validation; fields read off an untyped/`any` value; types
  that have drifted from the actual storage shape

**Cache correctness**

- Every write that changes displayed data invalidates or updates the cache entry that serves it
- Look for: mutations with no invalidation; cache keys that omit an input which changes the result
  (filter, tenant/account id, date range), which serves stale or cross-scope data; optimistic
  updates that don't match the server's response shape or don't roll back on error

**Idempotency & retries**

- Sync jobs, webhook handlers, and queue consumers must not double-apply work on retry or replay
- Look for: blind inserts where an upsert on a stable external id is needed; no dedupe key; partial
  writes with no transaction or compensating action

**Numeric precision**

- Values where exactness matters (money, quantities, percentages) must not accumulate floating-point
  drift; round at the display boundary, never mid-calculation
- Look for: repeated rounding inside a pipeline; mixing units or currencies without conversion;
  aggregate totals recomputed differently in two places

**Date & time handling**

- Look for: non-deterministic "now" inside calculations (makes behavior untestable and
  timezone-fragile); naive local-time arithmetic across DST; inconsistent serialization formats
  across boundaries

**Null, undefined, and partial writes**

- An omitted field, an explicit null, and an empty string are three different writes. Be intentional
- Look for: whole objects spread into an insert/update without an explicit field allowlist; defaults
  applied in one code path but not another

**Aggregation over partial data**

- Look for: totals summed client-side over a paginated or filtered subset, silently ignoring rows
  beyond the page — prefer a server-computed aggregate

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific focus areas (mobile-content-api)

**Publishing translations**

- `Translation#push_published_to_s3` pulls phrases from Crowdin (`CrowdinService.download_translated_phrases`), writes `translated_name`/`translated_description`/`translated_tagline` and the `TranslationAttribute` rows in a transaction, builds and uploads the zip with `Package`, and only then sets `is_published: true`. `PublishTranslationJob` (Sidekiq, `lock: :until_executed`) stores a failure in `publishing_errors`. Look for: `is_published` flipped before the upload succeeds; `before_destroy :prevent_destroy_published` bypassed; new versions created outside `create_new_version`; a required translated attribute that is skipped instead of raising `Error::TextNotFoundError`.

**Ordering and permission data**

- `ResourceScore` (`featured`, `featured_order` from 1 to `MAX_FEATURED_ORDER_POSITION`, `score` from 1 to `MAX_SCORE`) and `ResourceDefaultOrder#position` are kept per country, language and resource type family. `ResourceType::TOOL` ("tool") expands to `tract` and `cyoa`; writes resolve type ids through `ResourceType.orderable_ids_for!`.
- Countries are lowercase ISO alpha-2 codes, kept that way by the `CountryCodes` concern (validation plus `downcase_country`). Country is a permission key: `ResourceScorePolicy` matches grants to scores by exact string, so every model that stores a country includes `CountryCodes`.
- Grant maps (`{"us" => ["*"], "mx" => ["es"]}`) are normalized and resolved only through `ResourceScoreGrants` (`normalize_map`, `resolve`, `resolve_lenient`). `ResourceScorePermission::ALL_LANGUAGES` (`"*"`), stored as a `nil` `language_id`, means every language in the country.

**Caching**

- `GET /resources` serves `cached_index_json`, keyed by `Resource.index_cache_key` (the relation's `cache_key_with_version` plus the include and fields params). A write that changes that output must change the key: `belongs_to :resource, touch: true` (as `Translation` and `Page` do) or `after_commit :clear_resource_cache` (as `ResourceScore` and `ResourceDefaultOrder` do, with `Rails.cache.delete_matched("cache::resources/*")`). Look for: a new model or column that `ResourceSerializer` emits with neither; `update_column`, `update_all` or `delete_all` that skip callbacks and touches on that data.
- ActionCable pairing state lives in `Rails.cache` with `METADATA_EXPIRY` (`BaseSharingChannel`).

**Migrations and schema**

- Migrations use `ActiveRecord::Migration[8.0]` or newer with `change`; `db/schema.rb` is committed and marked generated. Postgres types are in use (`citext` emails, `jsonb` grants). Look for: `null: false` added to a populated column without a default or backfill; a uniqueness rule that depends on time (like "one pending invite per email") pushed into a partial index; large-table index builds (`translations`, `resource_scores`, `user_counters`) without thought about the write lock.

### From PR history

- `db/schema.rb` changes must match the PR's migrations exactly: the `define(version:)` equals the newest migration timestamp, and no table, column, index or foreign key appears without a migration in the diff. A schema dumped from a local database pulls in tables from other branches. Flag schema drift that no migration explains.
  <!-- evidence: PR #2045, #2042, #2039 -->
- A blank or missing value must never widen access or wipe data. Every-language access is the explicit `ResourceScorePermission::ALL_LANGUAGES` (`"*"`), never a blank `lang`; an empty grants list must not silently revoke unless that is what the endpoint documents; a non-admin invite must carry at least one grant (`UserInvite#grants_or_admin_present`). Flag fallbacks that turn nil, `""` or `[]` into "all" or "none" without an error.
  <!-- evidence: PR #2045 (review on #2037), #2049 -->
- Every new foreign key chooses `on_delete:` on purpose (`:cascade` for rows that mean nothing without the parent, `:nullify` for audit links like `user_invites.invited_by_id`). Constraint errors the code can hit are handled: `ActiveRecord::InvalidForeignKey` and `ActiveRecord::RecordNotUnique` are not in `ApplicationController`'s `rescue_from` list and surface as 500s. For check-then-insert under concurrency, use a savepoint (`transaction(requires_new: true)`) and rescue `RecordNotUnique`, as `UserInvite#accept!` does.
  <!-- evidence: PR #2045 (review on #2037), #2048 (review on its fork predecessor #2043) -->
- Choose each validation's lifecycle on purpose. A uniqueness or conflict check that runs only `on: :create` misses PATCH and resend paths (`only_one_pending_per_email` had to cover updates and exclude its own `id`); a validator meant to guard creation must not block ordinary updates (#2016 removed `UsesCrowdinValidator` from `Page` after it 400ed renames). A new or tightened validation says what happens to existing rows: a backfill or data check, or an `if:` guard such as `will_save_change_to_grants?` so old rows can still be saved.
  <!-- evidence: PR #2048 (review on #2043), #2016, #2045, #2049 -->
- Ordering writes rewrite one whole slice: lock the slice's rows (`.lock` inside `ResourceScore.transaction`), clear, then renumber, and resolve the type through `ResourceType.orderable_ids_for!` so a write names `tool` or `lesson`, never `tract` or `cyoa` alone. A single-format write renumbers half the list and leaves colliding positions. Flag a new ordering write that takes a raw type name or skips the lock.
  <!-- evidence: PR #2046, #2045 -->
