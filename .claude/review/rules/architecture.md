# Architecture — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

**Layering & boundaries**

- Business logic lives in testable modules, not inline in entry points (route/page/controller/CLI
  handlers). Entry points compose and delegate
- Server-only code stays out of code paths that ship to a client or untrusted runtime
- Look for: domain math embedded in view code; a module reaching across layers it shouldn't know
  about; new circular dependencies

**Placement & structure**

- New files land where the existing convention says they belong; shared code goes to the shared
  location only when it is genuinely used by more than one feature
- Look for: one-off code dropped into a "shared"/"common"/"utils" bucket; parallel structures that
  duplicate an existing module instead of extending it; new top-level directories

**Pattern consistency**

- The change should look like the code around it. Deviating is fine when the existing pattern is
  what's being fixed — but then it should be fixed consistently, not forked
- Look for: a second way of doing something the codebase already does one way (data fetching, error
  handling, configuration, logging); framework features reimplemented by hand

**State & data flow**

- Cached/derived state has a clear owner, and writes invalidate or update what they affect
- Look for: the same state maintained in two places; refetching in an effect what a cache already
  owns; values threaded through three or more layers that would be better read closer to use

**Effects & lifecycle**

- Look for: effects whose dependency list omits referenced values (stale closures); work in an
  effect that belongs in an event handler or a derived value; subscriptions and timers without
  cleanup

**Concurrency & performance shape**

- Look for: sequential awaits on independent work that could run concurrently; N+1 query patterns;
  unbounded loops over remote calls; work done per-item that could be batched

**Error handling & resilience**

- Look for: swallowed errors (empty catch, error logged and ignored); failures that leave state
  half-written; missing error/loading boundaries on user-facing surfaces; retries without backoff or
  idempotency

**Technical debt**

- Weigh debt added against debt removed. A refactor that only moves code without improving clarity
  is neutral, not positive. When a convention is ambiguous, raise it as a question rather than a
  blocking finding

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific focus areas (mobile-content-api)

While `engine.name` is `code-review`, this lane does not run on its own; `/code-review` covers it, and this text feeds the scoring context.

- Layers: controllers (`app/controllers/`, thin, JSON:API in and out), then models with validations and callbacks (`app/models/`), services for outside systems (`app/services/`: Crowdin, Adobe Campaign, Salesforce, the OAuth providers, `ToolFilterService`, `UserInviteNotifier`), packaging and XML in `app/lib/` (`Package`, `XmlUtil`), and Sidekiq jobs (`app/sidekiq/`). Look for: S3, Crowdin or other HTTP calls made straight from a controller; a business rule kept in both a controller and a model.
- Shared base classes own the cross-cutting behavior: `ApplicationController` (JSON:API decoding, the `rescue_from` error handlers, `filter_param`, `require_admin!`, `require_login!`, token refresh), `SecureController`, `WithUserController`, `BaseAuthService`, `BaseSharingChannel`, `ApplicationPolicy`. A second copy of any of these in a new class is a pattern fork.
- Known duplication not to extend: the `Language.find_by_code` plus `raise InvalidRequestError, "Language not found for code: ..."` lookup repeated across `ResourceScoresController`, `ResourceDefaultOrdersController` and `ResourcesPersonalizationController#find_language!`, and the inline `rescue InvalidRequestError` blocks in `ResourceDefaultOrdersController`, `UserInvitesController` and `UserInviteAcceptancesController` that shadow the shared `rescue_from`. New code uses the shared path.
- Performance shape: `ResourceSerializer` emits about ten relationships, so any endpoint that renders a list of resources needs preloads (`ResourcesPersonalizationController#render_resources` preloads `resource_type` and `resource_attributes`) or a cache (`resources#index` serves `cached_index_json`). List endpoints with neither, and no pagination, grow with the catalog on every app launch.
- Publishing is asynchronous (`PublishTranslationJob`, unique while queued). Work that takes seconds (Crowdin downloads, zip building, S3 upload) belongs in the job, not the request.
