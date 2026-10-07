# frozen_string_literal: true

class UsersController < WithUserController
  DEFAULT_PAGE_SIZE = 25
  MAX_PAGE_SIZE = 100

  # The inherited subject authorization is per-user and meaningless for a
  # collection, so index swaps it for an admin gate. The enumeration guard is
  # unaffected: a non-admin gets no listing at all.
  skip_before_action :authorize_user!, only: :index
  before_action :require_admin!, only: :index

  def index
    scope = filtered_users
    total = scope.count

    render json: paginated(scope),
      include: params[:include],
      fields: field_params,
      meta: {
        total: total,
        page: page_number,
        size: page_size,
        pages: total.zero? ? 0 : (total.to_f / page_size).ceil
      },
      status: :ok
  end

  def show
    render json: @user, include: params[:include], fields: field_params
  end

  def destroy
    @user.destroy!
    render json: "", status: 204
  end

  def update
    @user.update!(user_params)
    @user.set_arbitrary_attributes!(data_attrs)

    render json: @user, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  protected

  def user_id_attribute
    :id
  end

  # Admins manage anyone; everyone else keeps the inherited self-only rule.
  def authorized_for_subject?
    current_user&.admin || super
  end

  private

  # JSON:API names mapped onto real columns. compact so an absent key leaves
  # the column alone rather than nulling it; false is kept, only nil dropped.
  def user_params
    permitted = data_attrs.permit(*update_keys)

    {
      email: permitted[:email],
      first_name: permitted[:"given-name"],
      last_name: permitted[:"family-name"],
      admin: permitted[:admin]
    }.compact
  end

  # Only an admin may set admin: a non-admin can PATCH their own record, so
  # permitting it unconditionally would be a self-promotion path.
  def update_keys
    keys = [:email, :"given-name", :"family-name"]
    keys << :admin if current_user&.admin
    keys
  end

  # UserSerializer reads user_attributes, both has_many relationships and the
  # grants' languages, so every row costs extra queries unless preloaded here.
  def paginated(scope)
    scope
      .includes(:user_attributes, :tools, :user_training_tips, resource_score_permissions: :language)
      .order(:id)
      .limit(page_size)
      .offset((page_number - 1) * page_size)
  end

  # One case-insensitive substring match across the name and email columns,
  # which is what an admin picking a user out of a list actually types. email is
  # citext so ILIKE on it is redundant, but keeping the clause uniform is
  # clearer than special-casing one column.
  def filtered_users
    scope = User.all
    term = search_term

    if term
      scope = scope.where(
        "email ILIKE :term OR name ILIKE :term OR first_name ILIKE :term OR last_name ILIKE :term",
        term: "%#{User.sanitize_sql_like(term)}%"
      )
    end

    countries = country_filter
    # Subquery, not a join: a join would repeat users granted two of the
    # selected countries and break the page count.
    if countries.any?
      scope = scope.where(
        id: ResourceScorePermission.where(country: countries).select(:user_id)
      )
    end

    scope
  end

  # filter[country][]=mx&filter[country][]=us -- OR within the facet. Downcased
  # because grants are stored lowercase and the client sends uppercase.
  def country_filter
    raw = nested_param(:filter, :country)
    return [] if raw.blank?

    Array(raw).filter_map { |code| code.to_s.strip.downcase.presence }.uniq
  end

  def search_term
    nested_param(:filter, :search)&.strip.presence
  end

  def page_number
    [nested_param(:page, :number).to_i, 1].max
  end

  def page_size
    requested = nested_param(:page, :size).to_i
    return DEFAULT_PAGE_SIZE unless requested.positive?

    [requested, MAX_PAGE_SIZE].min
  end

  # ?page=2 and ?filter=dan are not the nested JSON:API shape. Reading a scalar
  # as absent keeps a malformed query string a 200 with defaults, rather than a
  # 500 from indexing into a String.
  def nested_param(key, subkey)
    container = params[key]
    container.is_a?(ActionController::Parameters) ? container[subkey] : nil
  end
end
