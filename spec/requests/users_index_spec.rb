# frozen_string_literal: true

require "rails_helper"

describe "Users index", type: :request do
  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:editor) { FactoryBot.create(:user, admin: false) }

  def headers_for(user)
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  def json = JSON.parse(response.body)

  def ids = json["data"].map { |row| row["id"].to_i }

  def count_queries
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      queries << payload[:sql] unless %w[SCHEMA TRANSACTION].include?(payload[:name])
    end
    yield
    queries.size
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe "authorization" do
    it "rejects an anonymous caller" do
      get "/users", headers: {"Accept" => "application/vnd.api+json"}

      expect(response).to have_http_status(:unauthorized)
    end

    # The listing is the one thing the per-user enumeration guard cannot express,
    # so it gets its own assertion: a signed-in non-admin is refused outright.
    it "forbids a signed-in non-admin" do
      get "/users", headers: headers_for(editor)

      expect(response).to have_http_status(:forbidden)
      expect(json["data"]).to be_nil
    end

    it "allows an admin" do
      get "/users", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "listing" do
    it "returns every user as json:api user resources" do
      admin
      editor

      get "/users", headers: headers_for(admin)

      expect(ids).to match_array([admin.id, editor.id])
      expect(json["data"].map { |row| row["type"] }.uniq).to eq(["user"])
      expect(json["data"].first["attributes"]).to include("email")
    end

    # UserSerializer iterates user_attributes and serializes two has_many
    # relationships, so without the preload in #paginated the query count grows
    # with every row returned. Asserting the count is *unchanged* by adding
    # users is the invariant worth pinning; the absolute number is not.
    it "keeps the query count independent of how many users it returns" do
      headers = headers_for(admin)

      3.times { FactoryBot.create(:user_attribute, user_id: FactoryBot.create(:user).id) }
      baseline = count_queries { get "/users", headers: headers }
      expect(response).to have_http_status(:ok)

      3.times { FactoryBot.create(:user_attribute, user_id: FactoryBot.create(:user).id) }
      expect(count_queries { get "/users", headers: headers }).to eq(baseline)
      expect(json["meta"]["total"]).to eq(7)
    end

    it "orders by id so paging is stable" do
      users = FactoryBot.create_list(:user, 3)
      headers = headers_for(admin)

      get "/users", headers: headers

      expect(ids).to eq(([admin.id] + users.map(&:id)).sort)
    end
  end

  describe "pagination" do
    before { FactoryBot.create_list(:user, 4) }

    it "defaults to page 1 and reports totals in meta" do
      get "/users", headers: headers_for(admin)

      expect(json["meta"]).to include(
        "total" => 5, "page" => 1, "size" => 25, "pages" => 1
      )
      expect(json["data"].size).to eq(5)
    end

    it "honours page[number] and page[size]" do
      headers = headers_for(admin)
      all = User.order(:id).pluck(:id)

      get "/users?page[number]=2&page[size]=2", headers: headers

      expect(ids).to eq(all[2, 2])
      expect(json["meta"]).to include("total" => 5, "page" => 2, "size" => 2, "pages" => 3)
    end

    it "caps page[size] so one request cannot pull the whole table" do
      get "/users?page[size]=10000", headers: headers_for(admin)

      expect(json["meta"]["size"]).to eq(100)
      expect(json["meta"]["size"]).to eq(UsersController::MAX_PAGE_SIZE)
    end

    it "falls back to defaults for junk paging values" do
      get "/users?page[number]=0&page[size]=-3", headers: headers_for(admin)

      expect(json["meta"]).to include("page" => 1, "size" => 25)
    end

    # ?page=2 is a scalar, not the nested json:api shape. It must not 500.
    it "treats a scalar page param as absent" do
      get "/users?page=2", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json["meta"]).to include("page" => 1, "size" => 25)
    end

    it "reports zero pages when nothing matches" do
      get "/users?filter[search]=nobodyhasthisname", headers: headers_for(admin)

      expect(json["data"]).to eq([])
      expect(json["meta"]).to include("total" => 0, "pages" => 0)
    end
  end

  describe "filter[search]" do
    # The factory's default email is diana<n>@themyscira.pi, which would match
    # the searches below. The admin doing the searching needs a name and address
    # that share nothing with the users being searched for.
    let(:admin) do
      FactoryBot.create(:user, admin: true, first_name: "Root", last_name: "Admin",
        email: "root@example.org", name: "Root Admin")
    end

    let!(:diana) do
      FactoryBot.create(:user, first_name: "Diana", last_name: "Prince",
        email: "diana@themyscira.pi", name: "Diana Prince")
    end
    let!(:clark) do
      FactoryBot.create(:user, first_name: "Clark", last_name: "Kent",
        email: "clark@dailyplanet.com", name: "Clark Kent")
    end

    it "matches on email" do
      get "/users?filter[search]=themyscira", headers: headers_for(admin)

      expect(ids).to eq([diana.id])
    end

    it "matches on first name, case-insensitively" do
      get "/users?filter[search]=DIANA", headers: headers_for(admin)

      expect(ids).to eq([diana.id])
    end

    it "matches on last name" do
      get "/users?filter[search]=kent", headers: headers_for(admin)

      expect(ids).to eq([clark.id])
    end

    it "matches on the display name" do
      get "/users?filter[search]=Clark Kent", headers: headers_for(admin)

      expect(ids).to eq([clark.id])
    end

    it "matches a substring rather than requiring the whole value" do
      get "/users?filter[search]=rinc", headers: headers_for(admin)

      expect(ids).to eq([diana.id])
    end

    it "ignores a blank search rather than matching nothing" do
      get "/users?filter[search]=   ", headers: headers_for(admin)

      expect(ids).to include(diana.id, clark.id)
    end

    # Without escaping, a bare % is a LIKE wildcard and would match every row.
    # Passed as params rather than in the raw path: a literal % in a query
    # string is an invalid escape sequence and Rack rejects it before it
    # reaches the controller.
    it "treats LIKE metacharacters as literal text" do
      get "/users", params: {filter: {search: "%"}}, headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to eq([])
    end

    it "treats an underscore as literal text too" do
      get "/users", params: {filter: {search: "_"}}, headers: headers_for(admin)

      expect(json["data"]).to eq([])
    end

    it "counts matches, not the whole table, in meta" do
      FactoryBot.create_list(:user, 3)

      get "/users?filter[search]=kent", headers: headers_for(admin)

      expect(json["meta"]).to include("total" => 1, "pages" => 1)
    end

    # ?filter=dan is a scalar, not the nested json:api shape. It must not 500.
    it "treats a scalar filter param as absent" do
      get "/users?filter=diana", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ids).to include(diana.id, clark.id)
    end
  end
  describe "filter[country]" do
    let!(:mx_user) { FactoryBot.create(:user).tap { |u| u.resource_score_permissions.create!(country: "mx") } }
    let!(:us_user) { FactoryBot.create(:user).tap { |u| u.resource_score_permissions.create!(country: "us") } }
    let!(:both_user) do
      FactoryBot.create(:user).tap do |u|
        u.resource_score_permissions.create!(country: "mx")
        u.resource_score_permissions.create!(country: "us")
      end
    end
    let!(:ungranted) { FactoryBot.create(:user) }

    it "narrows to users granted the country" do
      get "/users", params: {filter: {country: ["mx"]}}, headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ids).to match_array([mx_user.id, both_user.id])
    end

    it "ORs within the facet" do
      get "/users", params: {filter: {country: ["mx", "us"]}}, headers: headers_for(admin)

      expect(ids).to match_array([mx_user.id, us_user.id, both_user.id])
    end

    it "returns a user granted two selected countries only once" do
      get "/users", params: {filter: {country: ["mx", "us"]}}, headers: headers_for(admin)

      expect(ids.count(both_user.id)).to eq(1)
      expect(json["meta"]["total"]).to eq(3)
    end

    it "is case-insensitive, since the client sends uppercase codes" do
      get "/users", params: {filter: {country: ["MX"]}}, headers: headers_for(admin)

      expect(ids).to match_array([mx_user.id, both_user.id])
    end

    it "ignores an empty filter rather than matching nothing" do
      get "/users", params: {filter: {country: []}}, headers: headers_for(admin)

      expect(ids).to include(ungranted.id)
    end
  end

end
