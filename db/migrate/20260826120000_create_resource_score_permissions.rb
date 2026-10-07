# frozen_string_literal: true

class CreateResourceScorePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :resource_score_permissions do |t|
      t.references :user, null: false, foreign_key: true
      # Every grant is anchored to a country -- country has precedence in the org
      # chart, so there is no such thing as a countryless grant.
      t.string :country, null: false
      # NULL language_id is the wildcard: "every language in this country".
      # Integer, not the bigint t.references would give: languages has a serial
      # primary key, and resource_scores.language_id is already integer.
      t.integer :language_id

      t.timestamps
    end

    # Postgres treats NULLs as distinct in a plain unique index, so the wildcard
    # row would be insertable many times over. Two partial indexes cover both cases.
    add_index :resource_score_permissions, %i[user_id country language_id],
      unique: true, where: "language_id IS NOT NULL",
      name: "index_resource_score_permissions_on_user_country_language"
    add_index :resource_score_permissions, %i[user_id country],
      unique: true, where: "language_id IS NULL",
      name: "index_resource_score_permissions_on_user_country_wildcard"
    add_index :resource_score_permissions, :language_id
    add_foreign_key :resource_score_permissions, :languages
  end
end
