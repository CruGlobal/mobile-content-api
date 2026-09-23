# frozen_string_literal: true

# A pending invitation to the admin dashboard, kept apart from users on
# purpose: the invitee may already exist as a user, and may be invited under an
# email alias that is not the address they log in to Okta with. The permissions
# ride on the invite and are merged into whichever user redeems it, so two user
# records never have to be reconciled.
class CreateUserInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :user_invites do |t|
      # citext, like users.email, so lookups are case-insensitive.
      t.citext :email, null: false
      t.string :first_name
      t.string :last_name
      # The form's "Use alias for user?" box. Not `alias`: it is a Ruby keyword.
      t.boolean :email_is_alias, null: false, default: false
      # Superadmin is users.admin; carried here so accepting can promote
      # without a manual DB flip.
      t.boolean :admin, null: false, default: false
      # Same shape the permissions mass_update takes and User#resource_score_grants
      # returns: {"us": ["*"], "mx": ["es"]}. Codes, not ids, so the map still
      # reads correctly if a language row changes underneath it.
      t.jsonb :grants, null: false, default: {}
      # The credential. Whoever presents it gets the grants -- there is no email
      # match on accept, by design (see the alias note above).
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.references :invited_by, foreign_key: {to_table: :users, on_delete: :nullify}
      # Set on redemption and never cleared: the row is the audit trail of who
      # accepted, which matters because the acceptor's Okta email can differ
      # from the invited one. A single use is enforced by accepted_at being set.
      t.references :accepted_by, foreign_key: {to_table: :users, on_delete: :nullify}
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :user_invites, :token, unique: true
    # Plain, not unique: "one live invite per email" cannot be a partial index
    # because it depends on expires_at vs now(). UserInvite enforces it.
    add_index :user_invites, :email
    add_index :user_invites, :expires_at
  end
end
