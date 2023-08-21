class User < ApplicationRecord
  has_many :user_counters, dependent: :destroy
  has_many :favorite_tools, dependent: :destroy
  has_many :tools, through: :favorite_tools

  has_many :user_attributes

  validates :sso_guid, uniqueness: true, presence: true, unless: -> { facebook_user_id.present? || google_user_id.present? || apple_user_id.present? }
  validates :email, presence: true

  def set_arbitrary_attributes!(data_attrs)
    data_attrs.each_pair do |key, value|
      attr_name = key[/^attr-(.*)$/, 1]
      next unless attr_name
      attr_name.tr!("-", "_")
      attribute = user_attributes.where(key: attr_name).first_or_initialize

      if value.nil?
        attribute.destroy unless attribute.new_record?
      else
        attribute.value = value.to_s
        attribute.save!
      end
    end
  end
end
