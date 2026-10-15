# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  type "user"
  attributes :sso_guid, :created_at, :name, :email, :admin
  attribute :first_name, key: "given-name"
  attribute :last_name, key: "family-name"

  # Lets a client learn its own access from the profile request it already makes.
  attribute :resource_score_grants, key: "resource-score-grants"

  has_many :tools, key: "favorite-tools"
  has_many :user_training_tips, key: "training-tips"

  def created_at
    object.created_at.iso8601 # without this, the default serializer datetime will add 3 ms digits which we prefer not to have
  end

  def attributes(*args)
    hash = super
    object.user_attributes.each { |attribute| hash["attr_#{attribute.key}"] = attribute.value }
    hash
  end
end
