# frozen_string_literal: true

class WithUserController < ApplicationController
  before_action :authorize!

  def authorize!
    # make sure we have a valid auth to begin with
    render_unauthorized and return unless authorization && current_user_id && current_user

    # all with user controllers also operate on a subject, sometimes "me".
    # we want this here, after the token is checked, but before the subject authorization is checked
    @user = params[user_id_attribute].blank? || params[user_id_attribute] == "me" ? current_user : User.find_by(id: params[user_id_attribute])

    # currently, if trying to operate on a specific @user, you can only operate on your own user data, but this may change later
    render_forbidden and return if @user != current_user
  end

  protected

  # extending classes can override this
  def user_id_attribute
    :user_id
  end
end
