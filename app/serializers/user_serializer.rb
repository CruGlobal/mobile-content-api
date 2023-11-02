# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  type "user"
  attributes :sso_guid, :created_at, :name, :email
  attribute :first_name, key: "given-name"
  attribute :last_name, key: "family-name"

  has_many :tools, key: "favorite-tools"

  def created_at
    object.created_at.iso8601 # without this, the default serializer datetime will add 3 ms digits which we prefer not to have
  end

  def attributes(*args)
    hash = super
    object.user_attributes.each { |attribute| hash["attr_#{attribute.key}"] = attribute.value }
    hash
  end
end
