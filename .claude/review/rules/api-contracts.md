# API Contracts: Focus Areas

Specialist lane for mobile-content-api's JSON:API surface. The GodTools Android and iOS apps and
the GodTools admin dashboard (`mobilecontentadmin.cru.org`) call these endpoints, and app versions
already in the field cannot be updated in step with the API. Treat every response field, status
code, param name and response header as a contract.

**Request shape**

- Bodies are JSON:API (`application/vnd.api+json`), merged into params by
  `ApplicationController#decode_json_api`, and read with `data_attrs` / `permit_params`
  (`params.require(:data).require(:attributes)`)
- Attribute and param names are dasherized on the wire (`given-name`, `email-is-alias`,
  `filter[resource-type]`) and mapped to columns in the controller (see
  `UserInvitesController#invite_params`)
- Filters are read with `filter_param(key)`, which honors only a scalar String and raises
  `InvalidRequestError` for arrays or hashes
- Look for: `params.dig(:filter, ...)` or `params[:filter][...]` in new code; a new param spelled
  with underscores next to dasherized siblings; `to_unsafe_h` on client input outside the existing
  `field_params` and `ranked_resources` reads

**Response shape**

- Serializers are `ActiveModel::Serializer` classes in `app/serializers/` with an explicit
  `type "..."` and `key: "dasherized-name"` on multiword attributes; the adapter is `:json_api`.
  `ApplicationController#render` sets `Content-Type: application/vnd.api+json` for `json:` renders
- Timestamps that clients compare go out as `iso8601` (see `UserInviteSerializer`); ids in
  attributes go out as strings (`invited_by_id&.to_s`)
- Look for: a serialized attribute or relationship removed or renamed; an attribute's type changed
  (integer vs string id, timestamp format); a new `has_many` the controller does not preload;
  `meta` keys renamed (`total`, `delivered`, `invite-url`, `skipped-grants`)

**Errors and status codes**

- Shared handlers in `ApplicationController`: `ActiveRecord::RecordNotFound` and
  `Error::NotFoundError` → 404; `Error::BadRequestError`, `ActiveRecord::RecordInvalid`,
  `Error::XmlError`, `Error::MultipleDraftsError`, `Error::TranslationError`,
  `RestClient::Exception` → 400; `Error::TextNotFoundError` → 409; `Pundit::NotAuthorizedError` →
  403; `InvalidRequestError` → 422. All render `ErrorSerializer` through `render_api_error` /
  `render_error`
- What each code means here: 400 = the request is missing something required
  (`Error::BadRequestError`); 422 = well formed but names something invalid (unknown language code,
  bad filter shape: `InvalidRequestError`); 401 = no or expired token; 403 = valid token, not
  allowed; 409 = conflicts with existing state (accepted invite, pending-email collision); 410 =
  expired invite
- Look for: a new inline `rescue` or hand-built `{errors: [{detail: ...}]}` body where a shared
  handler already applies; status codes that disagree with the PR description

**Headers and CORS**

- Custom response headers use `X-` names (`X-Auth-Renewal`). A header the browser dashboard must
  read is listed in `expose:` in the `Rack::Cors` blocks in `config/environments/production.rb`
  and the matching development and staging config
- Look for: a new response header missing from `expose:`; a standard request header name reused as
  a response header

**Compatibility checklist**

- [ ] No serialized attribute, relationship, `meta` key, route, or accepted param spelling is
      removed or renamed unless the PR body lists it as a breaking change and says which consumer
      (mobile release, dashboard branch) must ship first
- [ ] New params and attributes are dasherized; new routes follow the existing nesting and `path:`
      spelling (`tool-groups`, `default-order`, `rules-language`)
- [ ] Status codes follow the meanings above, and specs assert them
- [ ] Errors render through the shared handlers and `ErrorSerializer`
- [ ] Relationships the serializer emits are preloaded, and linkage is the complete related set

### From PR history

- Errors go through `ApplicationController`'s `rescue_from` handlers and `render_api_error`. Flag
  new action-level `rescue InvalidRequestError` or `rescue ActiveRecord::RecordInvalid` blocks that
  repeat a shared handler (a method-level `rescue` silently shadows `rescue_from` and forks the
  error shape), and new `code:` fields in error bodies: clients branch on the HTTP status. A
  controller-specific mapping belongs in a controller-level `rescue_from`.
  <!-- evidence: PR #2036, #2045 (review on its fork predecessor #2037), #2048 (review on its fork predecessor #2043) -->
- Read every filter through `filter_param`, and answer unknown or malformed values with a 4xx,
  never a 500 or a silently unfiltered 200. Flag `params.dig(:filter, ...)`, `.downcase` or
  `.split` on a raw filter value, and filters whose bad values fall back to a default list with no
  error.
  <!-- evidence: PR #2036, #2048 (review on #2043), #2049 -->
- A PR that drops or renames a param spelling, path or field, or changes a status code, lists it
  under breaking changes in its body, says which consumer must ship first (for example "the
  dashboard's `main` still sends `tract`"), and keeps a spec that pins the new behavior (old
  spelling ignored or rejected, retired path returns 404). Flag silent removals, above all ones
  where the old spelling now returns a 200 with unfiltered data.
  <!-- evidence: PR #2036, #2046 -->
- New wire names follow the house spelling: dasherized params and paths (`filter[resource-type]`,
  `/resources/default-order`), and `X-` prefixed custom response headers that are listed in the
  CORS `expose:` lists. Live endpoints keep their old spelling (`resources#index` still reads
  `filter[resource_type]`) until the clients move.
  <!-- evidence: PR #2020, #2036, #2046 -->
- Preload what the serializer will touch, and nothing else. Flag `includes(:assoc)` combined with
  a `where` on that same association (it loads a partial set, so the JSON:API linkage is
  incomplete), serializer `belongs_to` links that only repeat the route's own id, `includes` the
  serializer never reads, and `.size` on an unloaded relation that is about to be rendered (load
  it once, then count).
  <!-- evidence: PR #2036, #2045 (review on #2037), #2048 (review on #2043) -->
