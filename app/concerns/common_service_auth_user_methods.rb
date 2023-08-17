# app/concerns/common_service_auth_methods.rb
module CommonServiceAuthUserMethods
  extend ActiveSupport::Concern

  def self.user_existence_validation(create_user, users)
    raise ::UserAlreadyExist::Error if user_already_exist(create_user, users)
    raise ::UserNotFound::Error if user_not_found(create_user, users)
  end

  def self.first_or_initialize_user(primary_key, id, user_atts)
    user = User.where(primary_key => id).first_or_initialize
    user.update!(user_atts)
    user
  end

  def self.new_user(primary_key, id, user_atts)
    user = User.new(primary_key => id)
    user.update!(user_atts)
    user
  end

  def self.existent_user(create_user, users)
    users[0] if !create_user && !create_user.nil? && !users.empty?
  end

  def self.user_already_exist(create_user, users)
    create_user && !users.empty?
  end

  def self.user_not_found(create_user, users)
    !create_user && !create_user.nil? && users.empty?
  end
end
