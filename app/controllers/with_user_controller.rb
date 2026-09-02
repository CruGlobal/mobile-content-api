# frozen_string_literal: true

class WithUserController < ApplicationController
  before_action :authorize_user!

  def authorize_user!
    # make sure we have a valid auth to begin with
    render_unauthorized and return unless authorization && current_user

    # all with user controllers also operate on a subject, sometimes "me".
    # we want this here, after the token is checked, but before the subject authorization is checked
    @user = (params[user_id_attribute].blank? || params[user_id_attribute] == "me") ? current_user : User.find_by(id: params[user_id_attribute])

    # currently, if trying to operate on a specific @user, you can only operate on your own user data, but this may change later
    render_forbidden and return unless authorized_for_subject?
  end

  protected

  # extending classes can override this
  def user_id_attribute
    :user_id
  end

  # Who may act on the subject. Extending classes widen this when someone other
  # than the subject qualifies (an admin, say). Keep the answer independent of
  # whether the subject exists: @user is loaded with find_by and an unknown id
  # is refused the same way as one the caller simply may not touch, so the
  # response can't be used to enumerate user ids.
  def authorized_for_subject?
    @user == current_user
  end
end
